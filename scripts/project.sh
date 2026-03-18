#!/usr/bin/env zsh

set -euo pipefail

PROJ=$(basename $PWD)

if [[ -n ${1-} ]]; then
    SESSION_NAME="$PROJ-$1"
    REPO="$PWD/worktrees/$PROJ-$1"
else
    SESSION_NAME="$PROJ"
    REPO="$PWD/repo"
fi

PROJ_ENV="$PWD/config/env.zsh"
if [[ -f "$PROJ_ENV" ]]; then
    source "$PROJ_ENV"
fi

SESSION_ENV="$PWD/config/$SESSION_NAME/env.zsh"
if [[ -f "$SESSION_ENV" ]]; then
    source "$SESSION_ENV"
fi

cd "$REPO"

tmux-4.sh "$SESSION_NAME"
