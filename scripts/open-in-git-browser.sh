#! /bin/bash

echo 'Open in Browser...'
SHA=$1
REPO_URL=$(git remote get-url origin)
if [ -n $REPO_URL ]; then
	URL=${REPO_URL%%.git}/commit/${SHA}
	open ${URL}
fi

# Mac/Linux/Windows git-bash 一条命令更新本地git仓库地址
#REPO_URL=$(git remote get-url origin) && git remote set-url origin https://git${REPO_URL##http://git-kk}

# 获取原先git仓库地址
#git remote get-url origin
# 获取旧仓库地址后, 将地址中的域名 http://git-kk.landray.com.cn 替换为 https://git.landray.com.cn 即为新的git仓库地址
#git remote set-url origin <新git仓库地址>
