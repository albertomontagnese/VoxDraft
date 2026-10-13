#!/bin/bash
set -euo pipefail

: "${APP_STORE_TEAM_ID:?Set APP_STORE_TEAM_ID}"
: "${ASC_PRIVATE_KEY:?Set ASC_PRIVATE_KEY to the existing .p8 key path}"
: "${ASC_KEY_ID:?Set ASC_KEY_ID}"
: "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUN="$ROOT/build-appstore/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN"
cat > "$RUN/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>export</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>$APP_STORE_TEAM_ID</string>
</dict></plist>
PLIST

cd "$ROOT"
xcodebuild -project VoxDraft.xcodeproj -scheme VoxDraft -configuration Release \
  -destination 'generic/platform=macOS' -archivePath "$RUN/VoxDraft.xcarchive" \
  -derivedDataPath "$ROOT/build-appstore/DerivedData" \
  DEVELOPMENT_TEAM="$APP_STORE_TEAM_ID" CODE_SIGN_STYLE=Automatic \
  CODE_SIGN_ENTITLEMENTS=VoxDraft/VoxDraftAppStore.entitlements \
  ENABLE_APP_SANDBOX=YES SWIFT_ACTIVE_COMPILATION_CONDITIONS=APP_STORE \
  -allowProvisioningUpdates -authenticationKeyPath "$ASC_PRIVATE_KEY" \
  -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  archive

xcodebuild -exportArchive -archivePath "$RUN/VoxDraft.xcarchive" \
  -exportOptionsPlist "$RUN/ExportOptions.plist" -exportPath "$RUN/export" \
  -allowProvisioningUpdates -authenticationKeyPath "$ASC_PRIVATE_KEY" \
  -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID"

pkgutil --check-signature "$RUN/export/VoxDraft.pkg"
printf '\nApp Store package: %s\n' "$RUN/export/VoxDraft.pkg"
