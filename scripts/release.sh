#!/bin/bash
# Build, sign, zip and appcast a Sorap release.
# Usage: scripts/release.sh <version>      e.g. scripts/release.sh 2.7.2
set -euo pipefail
cd "$(dirname "$0")/.."

IDENTITY="Sorap Self-Signed"
REPO_SLUG="colamong/sorap"
INFO_PLIST="Maccy/Info.plist"
OUT_DIR="build/release"
APP="$OUT_DIR/Build/Products/Release/Sorap.app"

die() { echo "error: $*" >&2; exit 1; }

find_sparkle_tool() {
  local tool="$1" found=""
  if [ -d "$OUT_DIR/SourcePackages" ]; then
    found="$(find "$OUT_DIR/SourcePackages" -type f -path "*/sparkle/Sparkle/bin/$tool" 2>/dev/null | head -1)"
  fi
  if [ -z "$found" ] && [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
    found="$(find "$HOME/Library/Developer/Xcode/DerivedData" -type f -path "*/sparkle/Sparkle/bin/$tool" 2>/dev/null | head -1)"
  fi
  [ -n "$found" ] || die "Sparkle's $tool not found under $OUT_DIR/SourcePackages or ~/Library/Developer/Xcode/DerivedData"
  echo "$found"
}

# --- 1. Preflight -----------------------------------------------------------

VERSION="${1:-}"
[ -n "$VERSION" ] || die "version argument is required (usage: scripts/release.sh <version>)"
[[ "$VERSION" =~ ^[0-9]+(\.[0-9]+)*$ ]] || die "version '$VERSION' must look like 2.7.2"

# build/ and .superpowers/ are local scratch directories, not part of the check.
if [ -n "$(git status --porcelain -- . ':!build' ':!.superpowers')" ]; then
  git status --short -- . ':!build' ':!.superpowers' >&2
  die "working tree is not clean; commit or revert the changes above first"
fi

security find-identity -v -p codesigning | grep -Fq "\"$IDENTITY\"" \
  || die "code-signing identity '$IDENTITY' not found in the keychain (security find-identity -v -p codesigning)"

/usr/libexec/PlistBuddy -c "Print :SUPublicEDKey" "$INFO_PLIST" >/dev/null 2>&1 \
  || die "SUPublicEDKey is missing in $INFO_PLIST; run scripts/set-sparkle-key.sh first"

# generate_keys -p prints the public key of the EdDSA private key in the login keychain.
# generate_appcast signs the zip with that private key, so a missing key fails late and obscurely.
GENERATE_KEYS="$(find_sparkle_tool generate_keys)"
"$GENERATE_KEYS" -p >/dev/null 2>&1 \
  || die "no Sparkle EdDSA private key in the login keychain ('$GENERATE_KEYS -p' failed); restore it before releasing, or the update feed cannot be signed"

BUILD_NUMBER="$(git rev-list --count HEAD)"
ZIP="$OUT_DIR/Sorap-$VERSION.zip"

# --- 2. Build ---------------------------------------------------------------

echo "==> Building Sorap $VERSION (build $BUILD_NUMBER)"
xcodebuild -project Maccy.xcodeproj -scheme Maccy -configuration Release \
  -derivedDataPath "$OUT_DIR" \
  MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  CODE_SIGN_IDENTITY="$IDENTITY" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= ENABLE_HARDENED_RUNTIME=NO \
  clean build

[ -d "$APP" ] || die "build finished but $APP was not produced"

# --- 3. Verify signature ----------------------------------------------------

# First Authority line = the signing identity's name.
authority() { codesign -dvv "$1" 2>&1 | sed -n 's/^Authority=//p' | head -1; }

echo "==> Verifying signature"
codesign --verify --deep --strict "$APP" || die "codesign verification failed for $APP"
codesign -dv "$APP" 2>&1 | grep -E '^(Identifier|Format|Signature|Authority|TeamIdentifier)=' || true

SPARKLE="$APP/Contents/Frameworks/Sparkle.framework"
[ -d "$SPARKLE" ] || die "$SPARKLE is not embedded in the app"

APP_AUTH="$(authority "$APP")"
SPARKLE_AUTH="$(authority "$SPARKLE")"
echo "app authority:     ${APP_AUTH:-<none>}"
echo "Sparkle authority: ${SPARKLE_AUTH:-<none>}"

if [ "$APP_AUTH" != "$IDENTITY" ] || [ "$SPARKLE_AUTH" != "$IDENTITY" ]; then
  echo "==> Signer mismatch; re-signing Sparkle.framework and the app with '$IDENTITY'"
  # Sign nested code deepest first (never --deep), keeping each item's own entitlements and flags.
  # `requirements` is deliberately not preserved: the old designated requirement names the old signer.
  PRESERVE="entitlements,flags,runtime"
  # Longest path first guarantees children are signed before the bundle that contains them.
  while IFS= read -r nested; do
    codesign --force --sign "$IDENTITY" --preserve-metadata="$PRESERVE" "$nested"
  done < <({ find "$SPARKLE" -type d \( -name '*.xpc' -o -name '*.app' \)
             find "$SPARKLE" -type f -name Autoupdate; } \
           | awk '{ print length($0) "\t" $0 }' | sort -rn | cut -f2-)
  codesign --force --sign "$IDENTITY" --preserve-metadata="$PRESERVE" "$SPARKLE"
  codesign --force --sign "$IDENTITY" --preserve-metadata="identifier,$PRESERVE" "$APP"
  codesign --verify --deep --strict "$APP" || die "codesign verification still fails after re-signing"
  [ "$(authority "$APP")" = "$IDENTITY" ] && [ "$(authority "$SPARKLE")" = "$IDENTITY" ] \
    || die "signer is still not '$IDENTITY' after re-signing"
fi

FINAL_AUTH="$(authority "$APP")"
echo "==> Final signer: Authority=${FINAL_AUTH:-<none>}"
[ "$FINAL_AUTH" = "$IDENTITY" ] || die "app Authority is '${FINAL_AUTH:-<none>}', expected '$IDENTITY'; refusing to release"

# --- 4. Zip -----------------------------------------------------------------

echo "==> Creating $ZIP"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
SHA256="$(shasum -a 256 "$ZIP" | awk '{print $1}')"
echo "sha256: $SHA256"

# --- 5. Appcast -------------------------------------------------------------

GENERATE_APPCAST="$(find_sparkle_tool generate_appcast)"
APPCAST_DIR="$OUT_DIR/appcast"

echo "==> Generating appcast with $GENERATE_APPCAST"
rm -rf "$APPCAST_DIR"
mkdir -p "$APPCAST_DIR"
cp "$ZIP" "$APPCAST_DIR/"
[ -f appcast.xml ] && cp appcast.xml "$APPCAST_DIR/appcast.xml"
"$GENERATE_APPCAST" \
  --download-url-prefix "https://github.com/$REPO_SLUG/releases/download/v$VERSION/" \
  "$APPCAST_DIR"
[ -f "$APPCAST_DIR/appcast.xml" ] || die "generate_appcast did not write $APPCAST_DIR/appcast.xml"
cp "$APPCAST_DIR/appcast.xml" appcast.xml

# --- 6. Next steps ----------------------------------------------------------

cat <<NEXT

Release $VERSION is ready.
  zip:    $ZIP
  sha256: $SHA256

Next steps:
  1. git add appcast.xml && git commit -m "chore: release $VERSION"
  2. gh release create v$VERSION "$ZIP" --repo $REPO_SLUG --title "Sorap $VERSION" --notes "<release notes>"
  3. Merge sorap-v1 into master, then push appcast.xml to master (the branch SUFeedURL points at).
  4. Update the Homebrew cask: version "$VERSION", sha256 "$SHA256"
NEXT
