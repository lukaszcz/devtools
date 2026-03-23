#!/usr/bin/env zsh

session_args=()

if [[ -n "${1:-}" ]]; then
  session_args=(-s "$1")
fi

emulate -L zsh
setopt extendedglob

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

tmux new-session "${session_args[@]}" "${tmux_env_args[@]}" \; \
  split-window -h \; \
  split-window -h \; \
  split-window -h \; \
  select-layout tiled \; \
  select-pane -t 0
