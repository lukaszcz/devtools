#!/usr/bin/env zsh

set -euo pipefail

export PROJ_DIR="$PWD"
PROJ=$(basename $PROJ_DIR)

usage() {
    echo "usage: $(basename "$0") open [branch]"
    echo "       $(basename "$0") new [-p parent] branch"
    echo "       $(basename "$0") {co|checkout} [-p parent] branch"
    exit 1
}

CMD="${1-}"
[[ -z "$CMD" ]] && usage
shift

case "$CMD" in
    open)
        BRANCH="${1-}"
        ;;
    new|co|checkout)
        PARENT=""
        while getopts "p:" opt; do
            case $opt in
                p) PARENT="$OPTARG" ;;
                *) usage ;;
            esac
        done
        shift $((OPTIND - 1))

        BRANCH="${1-}"
        if [[ -z "$BRANCH" ]]; then
            echo "error: $CMD requires a branch name" >&2
            exit 1
        fi
        ;;
    *)
        usage
        ;;
esac

if [[ -n "$BRANCH" ]]; then
    SESSION_NAME="$PROJ/$BRANCH"
    REPO="$PROJ_DIR/worktrees/$PROJ-$BRANCH"
else
    SESSION_NAME="$PROJ"
    REPO="$PROJ_DIR/repo"
fi

PROJ_ENV="$PROJ_DIR/config/env.sh"
if [[ -f "$PROJ_ENV" ]]; then
    source "$PROJ_ENV"
fi

SESSION_ENV="$PROJ_DIR/config/$SESSION_NAME/env.sh"
if [[ -f "$SESSION_ENV" ]]; then
    source "$SESSION_ENV"
fi

case "$CMD" in
    new|co|checkout)
        REPO_BRANCH=$(git -C "$PROJ_DIR/repo" rev-parse --abbrev-ref HEAD)
        PARENT="${PARENT:-$REPO_BRANCH}"

        if [[ "$PARENT" == "$REPO_BRANCH" ]]; then
            cd "$PROJ_DIR/repo"
        else
            cd "$PROJ_DIR/worktrees/$PROJ-$PARENT"
        fi

        if [[ "$CMD" == "new" ]]; then
            mkwt.sh -b "$BRANCH"
        else
            mkwt.sh "$BRANCH"
        fi
        ;;
esac

cd "$REPO"

tmux.sh "$SESSION_NAME"
