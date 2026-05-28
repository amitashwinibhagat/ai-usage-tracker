#!/bin/bash
#
#  release.sh
#  Claude Usage Tracker — Release & Appcast Generator
#
#  Usage:
#    ./scripts/release.sh              → Auto-increment build, keep current version
#    ./scripts/release.sh 3.2.0        → Set version 3.2.0, auto-increment build
#    ./scripts/release.sh 3.2.0 -b 42  → Set version 3.2.0, force build 42
#
#  Build numbers auto-increment to guarantee Sparkle detects new versions.
#  Only the main_app target's CURRENT_PROJECT_VERSION is incremented.
#

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────

PROJECT="Claude Usage.xcodeproj"
PBXPROJ="${PROJECT}/project.pbxproj"
SCHEME="Claude Usage"
APP_NAME="Claude Usage"
DMG_NAME="Claude-Usage-Tracker"

BUILD_DIR="$HOME/Library/Developer/Xcode/DerivedData/Claude_Usage-*/Build/Products/Release"
SPARKLE_BIN="$HOME/Library/Developer/Xcode/DerivedData/Claude_Usage-bjbkwslymauedbgbmmrgiluegsal/SourcePackages/artifacts/sparkle/Sparkle/bin"

APPCST_FILE="Claude Usage/Resources/appcast.xml"
APPCST_URL="https://amitashwinibhagat.github.io/claude-usage-tracker-private/appcast.xml"
DOWNLOADS_DIR="./releases"

# ─── Helpers ──────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ─── Parse Arguments ─────────────────────────────────────────────

NEW_VERSION=""
FORCE_BUILD=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--build) FORCE_BUILD="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [version] [-b build_number]"
            echo "  version       Optional: new MARKETING_VERSION (e.g., 3.2.0)"
            echo "  -b build      Optional: force a specific build number"
            exit 0 ;;
        *) NEW_VERSION="$1"; shift ;;
    esac
done

# ─── Step 1: Read Current Versions ───────────────────────────────

log "Reading current project versions..."

CURRENT_MARKETING=$(grep "MARKETING_VERSION" "$PBXPROJ" | head -1 | sed 's/.*= \(.*\);/    \1/' | tr -d ' ')
CURRENT_BUILD=$(grep "CURRENT_PROJECT_VERSION" "$PBXPROJ" | head -1 | sed 's/.*= \(.*\);/    \1/' | tr -d ' ')
log "  Current version: ${CURRENT_MARKETING} (build ${CURRENT_BUILD})"

# ─── Step 2: Determine New Build Number ──────────────────────────

if [ -n "$FORCE_BUILD" ]; then
    NEW_BUILD="$FORCE_BUILD"
    log "Forcing build number: ${NEW_BUILD}"
else
    NEW_BUILD=$((CURRENT_BUILD + 1))
    log "Auto-incrementing build: ${CURRENT_BUILD} → ${NEW_BUILD}"
fi

# ─── Step 3: Update MARKETING_VERSION if Changed ─────────────────

if [ -n "$NEW_VERSION" ] && [ "$NEW_VERSION" != "$CURRENT_MARKETING" ]; then
    log "Updating MARKETING_VERSION: ${CURRENT_MARKETING} → ${NEW_VERSION}"
    sed -i '' "s/MARKETING_VERSION = ${CURRENT_MARKETING};/MARKETING_VERSION = ${NEW_VERSION};/g" "$PBXPROJ"
    EFFECTIVE_VERSION="$NEW_VERSION"
else
    EFFECTIVE_VERSION="$CURRENT_MARKETING"
    if [ -n "$NEW_VERSION" ]; then
        log "Version already ${NEW_VERSION}, keeping it"
    fi
fi

# ─── Step 4: Update Build Number (only main app target entries) ──

log "Updating build number in pbxproj: ${CURRENT_BUILD} → ${NEW_BUILD}"
sed -i '' "s/CURRENT_PROJECT_VERSION = ${CURRENT_BUILD};/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" "$PBXPROJ"

# ─── Step 5: Verify ──────────────────────────────────────────────

UPDATED_BUILD=$(grep "CURRENT_PROJECT_VERSION" "$PBXPROJ" | head -1 | sed 's/.*= \(.*\);/    \1/' | tr -d ' ')
log "Build number in pbxproj: ${UPDATED_BUILD}"

# ─── Step 6: Build Release ───────────────────────────────────────

log "Building Release configuration (${EFFECTIVE_VERSION} build ${NEW_BUILD})..."
xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'platform=macOS' \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build 2>&1 | grep -E "error:|BUILD" || true

# ─── Step 7: Verify Built App Versions ───────────────────────────

APP_PATH=$(find $BUILD_DIR -name "${APP_NAME}.app" -type d -maxdepth 3 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${APP_NAME}.app" -path "*/Release/*" -type d -maxdepth 5 2>/dev/null | head -1)
fi
if [ -z "$APP_PATH" ]; then
    err "Could not find built ${APP_NAME}.app"
fi

BUILT_VERSION=$(defaults read "$APP_PATH/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "?")
BUILT_BUILD=$(defaults read "$APP_PATH/Contents/Info" CFBundleVersion 2>/dev/null || echo "?")
log "Built app: v${BUILT_VERSION} (build ${BUILT_BUILD})"

# ─── Step 8: Create DMG ─────────────────────────────────────────

mkdir -p "$DOWNLOADS_DIR"
DMG_PATH="$DOWNLOADS_DIR/${DMG_NAME}-${EFFECTIVE_VERSION}-${NEW_BUILD}.dmg"

log "Creating DMG: $DMG_PATH"
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "$APP_PATH" \
    -ov -format UDZO \
    "$DMG_PATH" 2>&1 | tail -1

DMG_SIZE=$(du -sh "$DMG_PATH" | awk '{print $1}')
log "DMG created: ${DMG_SIZE}"

# ─── Step 9: Sign & Update Appcast ───────────────────────────────

log "Generating appcast with Sparkle signing..."
"$SPARKLE_BIN/generate_appcast" \
    --download-url-prefix "https://github.com/amitashwinibhagat/claude-usage-tracker-private/releases/download/v${EFFECTIVE_VERSION}/" \
    -o "$APPCST_FILE" \
    "$DOWNLOADS_DIR"

log "Appcast updated: $APPCST_FILE"

# ─── Step 10: Print Summary ──────────────────────────────────────

NEXT_BUILD=$((NEW_BUILD + 1))

cat << EOF

  ╔══════════════════════════════════════════════════════════════╗
  ║   Release v${EFFECTIVE_VERSION} Build ${NEW_BUILD}
  ╠══════════════════════════════════════════════════════════════╣
  ║  DMG:       ${DMG_PATH}
  ║  Size:      ${DMG_SIZE}
  ║  Appcast:   ${APPCST_FILE}
  ║  Feed URL:  ${APPCST_URL}
  ╚══════════════════════════════════════════════════════════════╝

  Deploy checklist:
  □ 1. Upload DMG to GitHub Releases: v${EFFECTIVE_VERSION}
     Filename: ${DMG_NAME}-${EFFECTIVE_VERSION}-${NEW_BUILD}.dmg
  □ 2. Upload appcast.xml to GitHub Pages:
     gh-pages branch → /appcast.xml
  □ 3. Verify feed URL returns valid XML:
     curl -sI ${APPCST_URL}
  □ 4. Commit bumped build number:
     git add "${PBXPROJ}" && \\
     git commit -m "Bump build to ${NEW_BUILD} [v${EFFECTIVE_VERSION}]"

  Next release:
     ./scripts/release.sh              # build ${NEXT_BUILD}
     ./scripts/release.sh 3.3.0        # new minor version
     ./scripts/release.sh -b 100       # force build 100

EOF

echo "  (Next build will be: ${NEXT_BUILD})"
