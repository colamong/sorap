#!/bin/bash
# Write the Sparkle EdDSA public key (from the login keychain) into Maccy/Info.plist.
# Usage: scripts/set-sparkle-key.sh
set -euo pipefail
cd "$(dirname "$0")/.."

INFO_PLIST="Maccy/Info.plist"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"

die() { echo "error: $*" >&2; exit 1; }

GENERATE_KEYS=""
for root in build/release/SourcePackages "$DERIVED_DATA"; do
  [ -d "$root" ] || continue
  GENERATE_KEYS="$(find "$root" -type f -path "*/sparkle/Sparkle/bin/generate_keys" 2>/dev/null | head -1)"
  [ -n "$GENERATE_KEYS" ] && break
done
[ -n "$GENERATE_KEYS" ] || die "Sparkle's generate_keys not found; build the project once so SPM fetches Sparkle"

# -p prints the public key of the key already in the keychain.
if ! KEY="$("$GENERATE_KEYS" -p 2>/dev/null)" || [ -z "$KEY" ]; then
  die "no Sparkle EdDSA key in the login keychain yet; run '$GENERATE_KEYS' once to create it, then rerun this script"
fi
KEY="$(printf '%s' "$KEY" | tr -d '[:space:]')"

if /usr/libexec/PlistBuddy -c "Print :SUPublicEDKey" "$INFO_PLIST" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Set :SUPublicEDKey $KEY" "$INFO_PLIST"
else
  /usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string $KEY" "$INFO_PLIST"
fi
echo "SUPublicEDKey = $KEY ($INFO_PLIST)"
