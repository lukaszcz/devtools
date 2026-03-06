#!/usr/bin/env bash

git branch | grep -v main | grep -v '*' | xargs git branch -D
