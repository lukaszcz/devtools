#!/usr/bin/env bash

set -euo pipefail

default_worktrees_dir() {
    local current_dir parent_dir grandparent_dir

    current_dir=$(basename "$PWD")
    parent_dir=$(basename "$(dirname "$PWD")")
    grandparent_dir=$(dirname "$(dirname "$PWD")")

    if [ "$current_dir" = "repo" ] && [ -d "$(dirname "$PWD")/worktrees" ]; then
        printf '%s\n' "../worktrees"
    elif [ "$parent_dir" = "worktrees" ] && [ -d "$grandparent_dir/repo" ]; then
        printf '%s\n' ".."
    elif [ -d "$PWD/repo" ] && [ -d "$PWD/worktrees" ]; then
        printf '%s\n' "worktrees"
    else
        printf '%s\n' ".worktrees"
    fi
}

CREATE_BRANCH=false
WORKTREES_DIR=$(default_worktrees_dir)
while getopts "b:d:" opt; do
    case $opt in
        b) CREATE_BRANCH=true; BRANCH="$OPTARG" ;;
        d) WORKTREES_DIR="$OPTARG" ;;
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
DIRNAME="${WORKTREES_DIR%/}/$BASEDIR-$BRANCH"

if $CREATE_BRANCH; then
    git worktree add -b "$BRANCH" "$DIRNAME"
else
    git worktree add "$DIRNAME" "$BRANCH"
fi
cp -r .setup.sh .env .env.local .config .agents .opencode .codex .claude .mcp.json $DIRNAME 2>/dev/null || true

cd $DIRNAME

if [ -f .config/setup.sh ] && [ -x .config/setup.sh ]; then
    ./.config/setup.sh
fi

if [ -f .setup.sh ] && [ -x .setup.sh ]; then
    ./.setup.sh
fi
