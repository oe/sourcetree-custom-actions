#!/usr/bin/env swift

import Foundation

// MARK: - Configuration
let fileManager = FileManager.default
let homeDir = fileManager.homeDirectoryForCurrentUser
let sourceTreeSupportDir = homeDir.appendingPathComponent("Library/Application Support/SourceTree")
let actionsPlistURL = sourceTreeSupportDir.appendingPathComponent("actions.plist")
let destScriptsDirURL = sourceTreeSupportDir.appendingPathComponent("custom_actions_scripts")
let sourceScriptsDirURL = URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent("scripts")

// MARK: - Helper Functions
func printLog(_ message: String) {
    print(message)
}

func printError(_ message: String) {
    fputs("Error: \(message)\n", stderr)
}

// MARK: - Main Execution

// 1. Validate Environment
guard fileManager.fileExists(atPath: sourceScriptsDirURL.path) else {
    printError("./scripts directory not found. Please run this script from the repository root.")
    exit(1)
}

// 2. Prepare Destination Directory
do {
    if !fileManager.fileExists(atPath: destScriptsDirURL.path) {
        printLog("Creating custom scripts directory at \(destScriptsDirURL.path)...")
        try fileManager.createDirectory(at: destScriptsDirURL, withIntermediateDirectories: true, attributes: nil)
    }
} catch {
    printError("Failed to create destination directory: \(error)")
    exit(1)
}

// 3. Copy Scripts
do {
    printLog("Copying scripts...")
    let scriptFiles = try fileManager.contentsOfDirectory(at: sourceScriptsDirURL, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "sh" }
    
    for scriptURL in scriptFiles {
        let destURL = destScriptsDirURL.appendingPathComponent(scriptURL.lastPathComponent)
        
        // Remove existing file if present to ensure update
        if fileManager.fileExists(atPath: destURL.path) {
            try fileManager.removeItem(at: destURL)
        }
        
        try fileManager.copyItem(at: scriptURL, to: destURL)
        
        // Make executable (chmod +x)
        let attributes = try fileManager.attributesOfItem(atPath: destURL.path)
        if let currentPermissions = attributes[.posixPermissions] as? NSNumber {
            let newPermissions = currentPermissions.uint16Value | 0o111 // Add execute permission for user, group, other
            try fileManager.setAttributes([.posixPermissions: NSNumber(value: newPermissions)], ofItemAtPath: destURL.path)
        }
    }
} catch {
    printError("Failed to copy scripts: \(error)")
    exit(1)
}

// 4. Backup actions.plist
if fileManager.fileExists(atPath: actionsPlistURL.path) {
    let backupURL = actionsPlistURL.appendingPathExtension("bak")
    do {
        printLog("Backing up actions.plist to \(backupURL.lastPathComponent)...")
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        try fileManager.copyItem(at: actionsPlistURL, to: backupURL)
    } catch {
        printError("Failed to backup actions.plist: \(error)")
        // Continue even if backup fails? Probably safer to stop.
        exit(1)
    }
} else {
    printLog("actions.plist not found. It will be created.")
}

// 5. Modify actions.plist
printLog("Updating actions.plist...")

var existingActions: [Any] = []

if fileManager.fileExists(atPath: actionsPlistURL.path) {
    if let data = try? Data(contentsOf: actionsPlistURL) {
        // Unarchive logic
        do {
            let classes = [NSArray.self, NSDictionary.self, NSString.self, NSNumber.self, NSDate.self, NSData.self] as [AnyClass]
            if let loaded = try NSKeyedUnarchiver.unarchivedObject(ofClasses: classes, from: data) as? [Any] {
                existingActions = loaded
            }
        } catch {
            printLog("Warning: Could not unarchive existing actions.plist: \(error). Starting with empty list.")
        }
    }
}

// Helper to check duplicates
func actionExists(name: String) -> Bool {
    for action in existingActions {
        if let dict = action as? [String: Any],
           let existingName = dict["name"] as? String,
           existingName == name {
            return true
        }
    }
    return false
}

// Identify scripts to add
guard let installedScripts = try? fileManager.contentsOfDirectory(at: destScriptsDirURL, includingPropertiesForKeys: nil)
    .filter({ $0.pathExtension == "sh" }) else {
    printError("Could not read installed scripts directory.")
    exit(1)
}

for scriptURL in installedScripts {
    let scriptName = scriptURL.lastPathComponent
    
    // Generate Name: open-in-xcode.sh -> Open In Xcode
    let name = scriptName
        .replacingOccurrences(of: ".sh", with: "")
        .replacingOccurrences(of: "st-", with: "")
        .replacingOccurrences(of: "vs-", with: "")
        .replacingOccurrences(of: "-", with: " ")
        .split(separator: " ")
        .map { $0.prefix(1).uppercased() + $0.dropFirst() }
        .joined(separator: " ")
    
    if actionExists(name: name) {
        printLog("Skipping '\(name)' (already exists)")
        continue
    }
    
    // Determine type
    var params = "$REPO"
    var logAction = false
    var repoAction = true
    let fileAction = false
    
    if scriptName == "open-in-git-browser.sh" {
        params = "$SHA"
        logAction = true
        repoAction = false
    }
    
    // Construct Dictionary
    let newAction: [String: Any] = [
        "name": name,
        "target": scriptURL.path,
        "params": params,
        "separateWindow": false,
        "showFullOutput": false,
        "fileAction": fileAction,
        "repoAction": repoAction,
        "logAction": logAction,
        "shortcutKeyCode": -1,
        "shortcutKeyModifiers": 0,
        "shortcutKeyDisplay": ""
    ]
    
    printLog("Adding action: \(name)")
    existingActions.append(newAction)
}

// Save back
do {
    let data = try NSKeyedArchiver.archivedData(withRootObject: existingActions, requiringSecureCoding: false)
    try data.write(to: actionsPlistURL)
    printLog("Successfully updated actions.plist")
    printLog("Done! Please restart SourceTree.")
} catch {
    printError("Error saving actions.plist: \(error)")
    exit(1)
}
