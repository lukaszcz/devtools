#!/bin/bash

set -euo pipefail

WORKTREES_DIR=".worktrees/"
FORCE=false

while getopts "d:f" opt; do
    case $opt in
        d) WORKTREES_DIR="$OPTARG/" ;;
        f) FORCE=true ;;
        *) echo "usage: $0 [-d dir] [-f] <branch-name>"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -ne 1 ]; then
    echo "usage: $0 [-d dir] [-f] <branch-name>"
    exit 1
fi

BRANCH="$1"

BASEDIR=$(basename "$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -1)")
DIRNAME="$WORKTREES_DIR$BASEDIR-$BRANCH"

if [ ! -d "$DIRNAME" ]; then
    echo "Error: Worktree directory '$DIRNAME' does not exist"
    exit 1
fi

if $FORCE; then
    git worktree remove --force "$DIRNAME"
else
    git worktree remove "$DIRNAME"
fi

echo "Removed worktree: $DIRNAME"
