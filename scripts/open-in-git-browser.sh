#! /bin/bash

echo 'Open in Browser...'
SHA=$1
REPO_URL=$(git remote get-url origin)
if [ -n $REPO_URL ]; then
	URL=${REPO_URL%%.git}/commit/${SHA}
	open ${URL}
fi
