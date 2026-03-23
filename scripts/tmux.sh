#!/usr/bin/env zsh

emulate -L zsh
setopt extendedglob

usage() {
  print -u2 "Usage: ${0:t} [-n pane_count] [session_name]"
}

pane_count=4

while getopts ":n:" opt; do
  case "$opt" in
    n)
      if [[ $OPTARG != <-> ]] || (( OPTARG < 1 )); then
        print -u2 "Invalid pane count: $OPTARG"
        usage
        exit 1
      fi
      pane_count=$OPTARG
      ;;
    :)
      print -u2 "Option -$OPTARG requires an argument"
      usage
      exit 1
      ;;
    \?)
      print -u2 "Unknown option: -$OPTARG"
      usage
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

if (( $# > 1 )); then
  usage
  exit 1
fi

session_args=()

if [[ -n "${1:-}" ]]; then
  session_args=(-s "$1")
fi

# Exact variable names to skip.
local -a skip_names=(
  TMUX
  TERM
  DISPLAY
  PWD
  OLDPWD
  SHELL
  SHLVL
  LOGNAME
  USER
  _
)

# Variable-name prefixes to skip.
local -a skip_prefixes=(
  TMUX_
  TERM_
  SSH_
  DBUS_
  XDG_
)

local -a tmux_env_args
local line name value prefix
local skip

while IFS= read -r line; do
  name=${line%%=*}
  value=${line#*=}

  skip=0

  # Skip exact names.
  if (( ${skip_names[(Ie)$name]} )); then
    skip=1
  else
    # Skip matching prefixes.
    for prefix in "${skip_prefixes[@]}"; do
      if [[ $name == ${prefix}* ]]; then
        skip=1
        break
      fi
    done
  fi

  (( skip )) && continue

  tmux_env_args+=(-e "$name=$value")
done < <(env)

tmux_args=(
  new-session
  "${session_args[@]}"
  "${tmux_env_args[@]}"
)

for (( pane_index = 1; pane_index < pane_count; pane_index++ )); do
  tmux_args+=(
    ';'
    split-window -h
  )
done

tmux_args+=(
  ';'
  select-layout tiled
  ';'
  select-pane -t 0
)

tmux "${tmux_args[@]}"
