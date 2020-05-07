#! /bin/bash

REPO_URL=$(git remote get-url origin)
echo -n $REPO_URL | pbcopy