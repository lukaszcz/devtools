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

session_name="${1:-}"

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
local -a tmux_command
local -a session_name_args
local line name value prefix
local skip
local apply_layout_command
local script_dir
local target_session
local window_id
local window_width
local window_height
local -i pane_index
local -i should_detach

should_detach=0

if [[ -n "${TMUX:-}" ]]; then
  should_detach=1
fi

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

script_dir=${0:A:h}
apply_layout_command="$script_dir/tmux-apply-layout.sh $pane_count '#{window_id}' '#{window_width}' '#{window_height}'"

tmux_args=(
  new-session
  -c "$PWD"
  "${tmux_env_args[@]}"
)

if [[ -n "$session_name" ]]; then
  session_name_args=(-s "$session_name")
  tmux_args+=("${session_name_args[@]}")
fi

for (( pane_index = 1; pane_index < pane_count; pane_index++ )); do
  tmux_args+=(
    ';'
    split-window -d -h -c "$PWD"
  )
done

tmux_args+=(
  ';'
  run-shell "$apply_layout_command"
  ';'
  select-pane -t 0
)

if (( should_detach )); then
  target_session=$(tmux new-session -dP -F '#{session_name}' -c "$PWD" "${tmux_env_args[@]}" "${session_name_args[@]}")

  for (( pane_index = 1; pane_index < pane_count; pane_index++ )); do
    tmux split-window -d -h -t "${target_session}:0" -c "$PWD"
  done

  window_id=$(tmux display-message -p -t "${target_session}:0" '#{window_id}')
  window_width=$(tmux display-message -p -t "${target_session}:0" '#{window_width}')
  window_height=$(tmux display-message -p -t "${target_session}:0" '#{window_height}')
  "$script_dir/tmux-apply-layout.sh" "$pane_count" "$window_id" "$window_width" "$window_height"
  tmux select-pane -t "${target_session}:0.0"
  tmux switch-client -t "$target_session"
  exit $?
fi

tmux_command=(tmux "${tmux_args[@]}")
"${tmux_command[@]}"
