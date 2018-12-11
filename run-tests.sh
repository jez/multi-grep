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

ARGV=()
UPDATE=
VERBOSE=
while [[ $# -gt 0 ]]; do
  case $1 in
    --update)
      UPDATE=1
      shift
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    *)
      ARGV+=("$1")
      shift
      ;;
  esac
done

exe=.symbol-work/bin/multi-grep

if [ ${#ARGV[@]} -eq 0 ]; then
  info "Discovering tests..."
  tests=()
  while IFS=$'\n' read -r line; do
    tests+=("$line");
  done < <(find tests -name '*.in')
else
  tests=("${ARGV[@]}")
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

  argv="$(head -n 1 "$test")"
  if [ -z "$argv" ]; then
    error "└─ first line of input file must be the CLI args."
    failing_tests+=("$test")
    continue
  fi

  # shellcheck disable=SC2086
  if ! tail -n +2 "$test" | "$exe" $argv > "$actual" 2>&1; then
    error "└─ failed. Output:"
    cat "$actual"
    failing_tests+=("$test")
    continue
  elif [ -n "$VERBOSE" ]; then
    cat "$actual"
  fi

  if ! git diff "$expected" "$actual"; then
    if [ -n "$UPDATE" ]; then
      error "├─ output did not match expected."
      warn  "└─ Updating $expected"
      cat "$actual" > "$expected"
    else
      error "└─ output did not match expected."
    fi
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
  echo "    ./run-tests.sh ${failing_tests[*]}"
  echo

  exit 1
fi
