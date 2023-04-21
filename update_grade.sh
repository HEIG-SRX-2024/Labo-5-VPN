#!/bin/zsh
set -e

if [ -z "$1" ]; then
  echo "Please give directory"
  exit 1
fi

if [ ! -d "$1" ]; then
  echo "This directory doesn't exist"
  exit 1
fi

tmp=$(mktemp)
cd "$1"
echo "**Ces notes ne sont pas encore définitives**\n\n" > $tmp
pbv public.html | sed -e "s/<style.*\/style>//" >> $tmp
URL=$(gh pr edit 1 -F $tmp)
rm $tmp
open $URL
