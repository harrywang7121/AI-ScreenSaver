#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")"; pwd)"
BUILD_DIR="/tmp/LunchTalkSaver_build"
SAVER_NAME="LunchTalkSaver"
BUNDLE_ID="haoyu.LunchTalkSaver"
SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
FRAMEWORKS_DIR="$SDK_PATH/System/Library/Frameworks"

# Source files (screen saver specific)
SOURCES=(
    "$PROJECT_DIR/AI_ScreenSaver/ScreenSaverPlugin.swift"
    "$PROJECT_DIR/AI_ScreenSaver/SessionStore.swift"
    "$PROJECT_DIR/AI_ScreenSaver/SaverContentView.swift"
    "$PROJECT_DIR/AI_ScreenSaver/SharedComponents.swift"
)

echo "🔨 Building LunchTalkSaver.saver..."
echo "   Source files: ${#SOURCES[@]}"
for src in "${SOURCES[@]}"; do
    if [ ! -f "$src" ]; then
        echo "❌ Error: Source file not found: $src"
        exit 1
    fi
    echo "   ✓ $src"
done

# Clean and prepare
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$SAVER_NAME.saver/Contents/MacOS"
mkdir -p "$BUILD_DIR/$SAVER_NAME.saver/Contents/Resources"

# Create Info.plist
cat > "$BUILD_DIR/$SAVER_NAME.saver/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>LunchTalkSaver</string>
    <key>CFBundleIdentifier</key>
    <string>haoyu.LunchTalkSaver</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>LunchTalk Saver</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSPrincipalClass</key>
    <string>LunchTalkSaver.LunchTalkScreenSaverView</string>
</dict>
</plist>
EOF

echo "📝 Created Info.plist"

# Compile with swiftc
echo "🔧 Compiling Swift code..."
xcrun swiftc \
    "${SOURCES[@]}" \
    -module-name LunchTalkSaver \
    -emit-library \
    -o "$BUILD_DIR/$SAVER_NAME.saver/Contents/MacOS/$SAVER_NAME" \
    -framework ScreenSaver \
    -framework AppKit \
    -framework SwiftUI \
    -framework Combine \
    -framework Foundation \
    -swift-version 5

if [ $? -eq 0 ]; then
    echo "✅ Built successfully: $BUILD_DIR/$SAVER_NAME.saver"
    echo ""
    echo "📦 To install:"
    echo "   cp -r \"$BUILD_DIR/$SAVER_NAME.saver\" ~/Library/Screen\\ Savers/"
    echo ""
    echo "🔍 To verify:"
    echo "   ls -la ~/Library/Screen\\ Savers/$SAVER_NAME.saver"
    echo ""
    echo "🚀 Then open System Settings → Screen Saver to select it"
else
    echo "❌ Build failed"
    exit 1
fi
