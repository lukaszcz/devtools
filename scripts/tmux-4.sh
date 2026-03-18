#!/usr/bin/env bash

session_args=()

if [[ -n "${1:-}" ]]; then
  session_args=(-s "$1")
fi

tmux new-session "${session_args[@]}" \; \
  split-window -h \; \
  split-window -h \; \
  split-window -h \; \
  select-layout tiled \; \
  select-pane -t 0
