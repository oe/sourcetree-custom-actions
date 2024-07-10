#! /bin/bash

echo 'Open in Browser...'
SHA=$1
REPO_URL=$(git remote get-url origin)
if [ -z $REPO_URL ]; then
	exit
fi

# if REPO_URL starts with ssh:// then remove it
if [[ $REPO_URL == "ssh://"* ]]; then
	REPO_URL=${REPO_URL#ssh://}
fi

# if is git ssh clone link
if [[ $REPO_URL == "git@"* ]]; then
	REPO_URL=${REPO_URL#git@}
	REPO_URL=${REPO_URL/:/"/"}
	REPO_URL="https://"$REPO_URL
fi

# bitbucket related url
if [[ $REPO_URL == *"bitbucket."* ]]; then
	# get scheme, host and path from REPO_URL
	SCHEME=${REPO_URL%%://*}
	REPO_URL=${REPO_URL#*://}
	HOST_NAME=${REPO_URL%%/*}
	PATH_NAME=${REPO_URL#*/}
	GROUP_NAME=${PATH_NAME%%/*}
	REST_PATH=${PATH_NAME#*/}
	REPO_URL=${SCHEME}://${HOST_NAME}/projects/${GROUP_NAME}/repos/${REST_PATH}
	URL=${REPO_URL%%.git}/commits/${SHA}
else
	URL=${REPO_URL%%.git}/commit/${SHA}
fi

open ${URL}
