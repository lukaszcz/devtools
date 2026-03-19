#!/usr/bin/env zsh

set -euo pipefail

PROJ_ROOT="$PWD"
PROJ=$(basename $PROJ_ROOT)

CREATE_BRANCH=false
PARENT=""
while getopts "bp:" opt; do
    case $opt in
        b) CREATE_BRANCH=true ;;
        p) PARENT="$OPTARG" ;;
        *) echo "usage: $0 [-b] [-p parent-branch] [branch]"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

BRANCH="${1-}"

if [[ -n "$BRANCH" ]]; then
    SESSION_NAME="$PROJ-$BRANCH"
    REPO="$PROJ_ROOT/worktrees/$PROJ-$BRANCH"
else
    SESSION_NAME="$PROJ"
    REPO="$PROJ_ROOT/repo"
fi

if $CREATE_BRANCH; then
    if [[ -z "$BRANCH" ]]; then
        echo "error: -b requires a branch name" >&2
        exit 1
    fi

    DEFAULT_BRANCH=$(git -C "$PROJ_ROOT/repo" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo main)
    PARENT="${PARENT:-$DEFAULT_BRANCH}"

    if [[ "$PARENT" == "$DEFAULT_BRANCH" ]]; then
        cd "$PROJ_ROOT/repo"
    else
        cd "$PROJ_ROOT/worktrees/$PROJ-$PARENT"
    fi

    mkwt.sh -b "$BRANCH"
fi

PROJ_ENV="$PROJ_ROOT/config/env.zsh"
if [[ -f "$PROJ_ENV" ]]; then
    source "$PROJ_ENV"
fi

SESSION_ENV="$PROJ_ROOT/config/$SESSION_NAME/env.zsh"
if [[ -f "$SESSION_ENV" ]]; then
    source "$SESSION_ENV"
fi

cd "$REPO"

tmux-4.sh "$SESSION_NAME"
