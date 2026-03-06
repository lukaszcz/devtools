#!/usr/bin/env bash

set -euo pipefail

FORCE=false

while getopts "f" opt; do
    case $opt in
        f) FORCE=true ;;
        *) echo "usage: $0 [-f] <branch-name>"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -ne 1 ]; then
    echo "usage: $0 [-f] <branch-name>"
    exit 1
fi

BRANCH="$1"

# Find the worktree path for the given branch using git worktree list
WORKTREE_PATH=$(git worktree list --porcelain | awk -v branch="$BRANCH" '
    /^worktree / { path = substr($0, 10) }
    /^branch / && $2 == "refs/heads/" branch { print path; exit }
')

if [ -z "$WORKTREE_PATH" ]; then
    echo "Error: No worktree found for branch '$BRANCH'"
    echo "Available worktrees:"
    git worktree list
    exit 1
fi

if $FORCE; then
    git worktree remove --force "$WORKTREE_PATH"
else
    git worktree remove "$WORKTREE_PATH"
fi

echo "Removed worktree for branch '$BRANCH': $WORKTREE_PATH"

git branch -d "$BRANCH"
