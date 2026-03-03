#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

# Build latest saver
"$ROOT/build_saver.sh"

# Clean old test savers
rm -rf "$HOME/Library/Screen Savers/NetworkProof.saver" \
       "$HOME/Library/Screen Savers/ProofV3.saver" \
       "$HOME/Library/Screen Savers/LunchTalkSaverV2.saver" \
       "$HOME/Library/Screen Savers/LunchTalkSaver.saver"

# Install fresh
mkdir -p "$HOME/Library/Screen Savers"
cp -R "/tmp/LunchTalkSaver_build/LunchTalkSaver.saver" "$HOME/Library/Screen Savers/LunchTalkSaver.saver"

# Refresh
killall ScreenSaverEngine >/dev/null 2>&1 || true
killall WallpaperAgent >/dev/null 2>&1 || true
open "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension" || true

echo "Installed: ~/Library/Screen Savers/LunchTalkSaver.saver"
echo "Removed old savers: NetworkProof / ProofV3 / LunchTalkSaverV2"
