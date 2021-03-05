#! /bin/bash

echo 'Reset your git local changes...'
cd "$1"
git stash --include-untracked