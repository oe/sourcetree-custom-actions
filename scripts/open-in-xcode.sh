#! /bin/bash

echo 'Open Repo in XCode...'
cd "$1"
# find the first xcode project
PROJECT=$(find . -name "*.xcodeproj" | head -n 1)

if [[ -z "$PROJECT" ]]; then
	echo "No XCode Project found"
	exit 1
else
	open "$PROJECT"
fi

