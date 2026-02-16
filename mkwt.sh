#!/bin/bash

set -euo pipefail

CREATE_BRANCH=false
PARENT_DIR="../"
while getopts "b:d:" opt; do
    case $opt in
        b) CREATE_BRANCH=true; BRANCH="$OPTARG" ;;
        d) PARENT_DIR="$OPTARG/" ;;
        *) echo "usage: $0 [-b branch-name] [-d dir] [branch-name]"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if $CREATE_BRANCH; then
    if [ $# -ne 0 ]; then
        echo "usage: $0 [-b branch-name] [-d dir] [branch-name]"
        exit 1
    fi
else
    if [ $# -ne 1 ]; then
        echo "usage: $0 [-b branch-name] [-d dir] [branch-name]"
        exit 1
    fi
    BRANCH="$1"
fi

BASEDIR=$(basename "$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -1)")
DIRNAME="$PARENT_DIR$BASEDIR-$BRANCH"

if $CREATE_BRANCH; then
    git worktree add -b "$BRANCH" "$DIRNAME"
else
    git worktree add "$DIRNAME" "$BRANCH"
fi
cp -r .setup.sh .config .opencode .codex .claude .mcp.json $DIRNAME 2>/dev/null || true

if [ -f ./config/setup.sh ] && [ -x .config/setup.sh ]; then
    (cd $DIRNAME && ./.config/setup.sh)
fi

if [ -f .setup.sh ] && [ -x .setup.sh ]; then
    (cd $DIRNAME && ./.setup.sh)
fi
