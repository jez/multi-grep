#!/usr/bin/env bash

no_uncommitted() {
  git diff --quiet HEAD 2> /dev/null
}
no_untracked() {
  return "$(git ls-files -o -d --exclude-standard | head -n 1 | wc -l)"
}
is_clean() {
  no_uncommitted && no_untracked
}

if is_clean; then
  export STARTED_CLEAN=1
else
  export STARTED_CLEAN=
fi

