#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

echo "Create local git repo at ~/repositories/cnbc-hugo-site.git"
if [ ! -d ~/repositories/cnbc-hugo-site.git ]; then
  mkdir -p ~/repositories/cnbc-hugo-site.git
  cd ~/repositories/cnbc-hugo-site.git
  git --bare init

  export GIT_SSH_COMMAND="/usr/bin/ssh -o StrictHostKeyChecking=yes -i ~/.ssh/id_cnbc-sync-rsa"
  echo 'export GIT_SSH_COMMAND="/usr/bin/ssh -o StrictHostKeyChecking=yes -i ~/.ssh/id_cnbc-sync-rsa"' >>~/.bashrc

  git config --global user.email "you@example.com"
  git config --global user.name "you"

  export YOUR_GIT_HOST=jumpbox.local
  echo "export YOUR_GIT_HOST=jumpbox.local" >>~/.bashrc
else
  echo "The repo ~/repositories/cnbc-hugo-site.git, exists."
fi

if [ ! -d ~/cnbc-hugo-site ]; then
  echo "Clone local git repo to ~/cnbc-hugo-site"
  cd $HOME
  git clone ${USER}@${YOUR_GIT_HOST}:${HOME}/repositories/cnbc-hugo-site.git
  cd ~/cnbc-hugo-site

  echo "Create simple hugo site"
  docker run --rm --user $(id -u):$(id -g) -v $(pwd):/src hugomods/hugo hugo new site .

  git config --global init.defaultBranch main
  git init
  git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke
  cat >>hugo.toml <<EOF
theme = "ananke"

[params]
  background_color_class = "bg-yellow"
  
EOF
  mkdir -p content/posts/

  DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  cat >content/posts/my-first-post.md <<EOF
---
title: "CNBC News Post"
date: "$DATE"
draft: false
---

Hello Again
EOF

  echo "Commit and push simple hugo site"
  cd ~/cnbc-hugo-site
  git add .
  git commit -m "Initial checkin"
  git push
else
  echo "The first content at dir ~/cnbc-hugo-site, exists."
fi

echo "Usage: source ~/.bashrc"