#!/usr/bin/env bash

set -euo pipefail

source tests/logging.sh
source tests/git-helpers.sh

if ./symbol make with=smlnj; then
  success "Built cleanly under SML/NJ."
else
  error "Did not build cleanly under SML/NJ."
  exit 1
fi

# Want this to be second, so that it's what's used for tests (faster)
# Symbol ensures that if no source files have changed, this is instant.
if ./symbol make with=mlton; then
  success "Built cleanly under MLton."
else
  error "Did not build cleanly under MLton."
  exit 1
fi

exe=.symbol-work/bin/multi-grep

if [ $# -eq 0 ]; then
  tests=()
  while IFS=$'\n' read -r line; do
    tests+=("$line");
  done < <(find tests -name '*.in')
else
  tests=("$@")
fi

failing_tests=()
passing_tests=()
for test in "${tests[@]}"; do
  info "$test"

  expected="$(dirname "$test")/$(basename "$test" .in).exp"
  if ! [ -f "$expected" ]; then
    error "└─ missing .exp file ($expected)"
    failing_tests+=("$test")
    continue
  fi

  actual="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '$actual'" EXIT

  if [ "$(wc -l "$test")" -lt 2 ]; then
    error "└─ must have at least two lines in input file (first line is pattern)"
    failing_tests+=("$test")
    continue
  fi

  pattern="$(head -n 1 "$test")"

  if ! tail -n +2 "$test" | "$exe" "$pattern" > "$actual"; then
    error "└─ failed. Output:"
    cat "$actual"
    failing_tests+=("$test")
    continue
  fi

  if ! diff -u "$expected" "$actual"; then
    error "└─ output did not match expected."
    failing_tests+=("$test")
    continue
  fi

  if [ -n "$STARTED_CLEAN" ] && ! is_clean; then
    error "└─ test did not leave working directory clean."
    failing_tests+=("$test")
    continue
  fi

  success "└─ passed."
  passing_tests+=("$test")
done

echo

if [ "${#passing_tests[@]}" -ne 0 ]; then
  echo
  echo "───── Passing tests ────────────────────────────────────────────────────"
  for passing_test in "${passing_tests[@]}"; do
    success "$passing_test"
  done
fi

if [ "${#failing_tests[@]}" -ne 0 ]; then
  echo
  echo "───── Failing tests ────────────────────────────────────────────────────"

  for failing_test in "${failing_tests[@]}"; do
    error "$failing_test"
  done

  echo
  echo "There were failing tests. To re-run all failing tests:"
  echo
  echo "    ./run-tests.sh --verbose ${failing_tests[*]}"
  echo

  exit 1
fi
