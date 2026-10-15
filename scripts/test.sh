#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
ARGS=("$@")
if [ ${#ARGS[@]} -eq 0 ]; then ARGS=(-only-testing:MaccyTests); fi
xcodebuild test \
  -project Maccy.xcodeproj -scheme Maccy -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM= \
  "${ARGS[@]}" 2>&1 | grep -E 'Test Case .* failed|error:|\*\* (TEST|BUILD)|Executed' | tail -60
