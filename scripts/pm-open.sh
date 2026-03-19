#!/usr/bin/env zsh

set -euo pipefail

PROJ_ROOT="$PWD"
PROJ=$(basename $PROJ_ROOT)

if [[ -n ${1-} ]]; then
    SESSION_NAME="$PROJ-$1"
    REPO="$PROJ_ROOT/worktrees/$PROJ-$1"
else
    SESSION_NAME="$PROJ"
    REPO="$PROJ_ROOT/repo"
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
