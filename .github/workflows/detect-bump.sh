#!/bin/sh
set -e
# Detect version bump type from commit footers since last tag
# Outputs: major, minor, or patch
#
# Usage: Add a footer line "bump: major" or "bump: minor" to any commit
# to trigger that bump type. Otherwise defaults to patch.

# --match skips upstream's non-version "preview" tag
LAST_TAG=$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || echo "")

if [ -z "$LAST_TAG" ]; then
  COMMITS=$(git log --format=%B)
else
  COMMITS=$(git log "$LAST_TAG"..HEAD --format=%B)
fi

if echo "$COMMITS" | grep -qE '^bump: major$'; then
  echo "major"
elif echo "$COMMITS" | grep -qE '^bump: minor$'; then
  echo "minor"
else
  echo "patch"
fi
