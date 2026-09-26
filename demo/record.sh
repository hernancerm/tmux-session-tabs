#!/usr/bin/env bash

## Record `demo.mp4` from `demo.tape`. Run from anywhere: `demo/record.sh`.
## The projects are made fresh in `$HOME`, so the prompt and the tabs show real-looking paths.

set -euo pipefail

demo="$(cd "$(dirname "$0")" && pwd -P)"
root="${HOME}/tmux-tabs-demo"
# `demo.tape` types these paths, keep both in sync.
projects=(api website notes)

# Never delete a folder this script did not make.
if [[ -e "${root}" ]]; then
  echo "${root} already exists, remove it or pick another root" >&2
  exit 1
fi

cleanup() {
  tmux -L tabs-demo kill-server 2>/dev/null || true
  rm -rf "${root}"
}
trap cleanup EXIT

for project in "${projects[@]}"; do
  mkdir -p "${root}/${project}"
done

# Every shell in the demo, inside tmux or not, reads `zdotdir/.zshrc` instead of the user's.
export ZDOTDIR="${demo}/zdotdir"

cd "${demo}"
vhs demo.tape
