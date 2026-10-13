#!/bin/zsh
set -euo pipefail

: "${SIGNING_IDENTITY:?Set SIGNING_IDENTITY to your Developer ID Application certificate}"
: "${NOTARY_KEY_PATH:?Set NOTARY_KEY_PATH to the App Store Connect .p8 file}"
: "${NOTARY_KEY_ID:?Set NOTARY_KEY_ID}"
: "${NOTARY_ISSUER_ID:?Set NOTARY_ISSUER_ID}"

cd "${0:A:h}/.."

xcodebuild -project VoxDraft.xcodeproj -scheme VoxDraft \
  -configuration Release -derivedDataPath build-universal \
  -destination 'generic/platform=macOS' \
  ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO build -quiet

release_app='build-universal/Build/Products/Release/VoxDraft.app'
notary_zip='build-universal/VoxDraft-notary.zip'

codesign --force --deep --options runtime \
  --entitlements VoxDraft/VoxDraft.entitlements --timestamp \
  --sign "$SIGNING_IDENTITY" "$release_app"
codesign --verify --deep --strict "$release_app"
ditto -c -k --sequesterRsrc --keepParent "$release_app" "$notary_zip"
xcrun notarytool submit "$notary_zip" \
  --key "$NOTARY_KEY_PATH" --key-id "$NOTARY_KEY_ID" \
  --issuer "$NOTARY_ISSUER_ID" --wait
for attempt in 1 2 3; do
  if xcrun stapler staple "$release_app"; then break; fi
  if (( attempt == 3 )); then
    echo 'Could not staple the accepted notarization ticket after 3 attempts' >&2
    exit 1
  fi
  sleep 3
done
xcrun stapler validate "$release_app"
spctl --assess --type execute --verbose=2 "$release_app"
ditto "$release_app" VoxDraft.app
ditto -c -k --sequesterRsrc --keepParent "$release_app" VoxDraft-mac.zip
shasum -a 256 VoxDraft-mac.zip > VoxDraft-mac.zip.sha256
echo 'Created notarized VoxDraft-mac.zip'
