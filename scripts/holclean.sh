#!/usr/bin/env bash

set -euo pipefail

find . -name .hol | xargs rm -rf
rm -rf .holbuild || true
