#!/bin/bash -e

if [ -d students ]; then
  echo "Students directory already exists - abort"
  exit 1
fi

REPOS=$(gh repo list HEIG-SRX-2023 --json url --jq '.[] | .url' | grep labo-3)
for repo in $REPOS; do
  gh repo clone "${repo/https:\/\/github.com\//git@github.com:}"
done
