#! /bin/bash

echo 'Open in Browser...'
SHA=$1
REPO_URL=$(git remote get-url origin)
if [ -z $REPO_URL ]; then
	exit
fi

# if is git ssh clone link
if [[ $REPO_URL == "git@"* ]]; then
	REPO_URL=${REPO_URL#git@}
	REPO_URL=${REPO_URL/:/"/"}
	REPO_URL="https://"$REPO_URL
fi

URL=${REPO_URL%%.git}/commit/${SHA}
open ${URL}



