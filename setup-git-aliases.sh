#!/usr/bin/env bash

git config --global alias.st "status -sb"
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.wt worktree
git config --global alias.lg "log --oneline -10"
git config --global alias.lgs "log --oneline"
git config --global alias.dt '!git -c diff.external=difft diff "$@"'
