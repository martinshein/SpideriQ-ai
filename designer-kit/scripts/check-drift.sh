#!/bin/sh
# Fail if the committed runtimes/ tree differs from a fresh build of shared/.
#
# Run by `npm run build:check`, immediately after `npm run build`.
#
# Two things this deliberately does that a bare `git diff --quiet runtimes/`
# does not:
#
#   1. It uses `git status --porcelain`, so a build that emits a NEW file
#      nobody committed is caught. `git diff` ignores untracked paths, so an
#      added skill would have slipped through as a clean pass.
#   2. It prints how many files it compared, and fails on zero. A check that
#      passes having compared nothing reads exactly like a check that passes
#      having compared everything.
set -e
cd "$(dirname "$0")/.."

compared=$(git ls-files -- runtimes/ | wc -l | tr -d ' ')
echo "build:check — compared ${compared} committed file(s) under runtimes/"

if [ "$compared" -eq 0 ]; then
  echo "BUILD CHECK VACUOUS — zero files under runtimes/ were compared."
  echo "The gate cannot pass on an empty comparison. Is runtimes/ committed?"
  exit 1
fi

drift=$(git status --porcelain -- runtimes/)
if [ -n "$drift" ]; then
  echo "BUILD DRIFT — runtimes/ differs from committed state:"
  echo "$drift"
  echo
  echo "shared/ is the source; runtimes/ is generated. Run 'npm run build' and"
  echo "commit the result — never hand-edit a file under runtimes/."
  exit 1
fi

echo "build:check OK — runtimes/ matches a fresh build of shared/."
