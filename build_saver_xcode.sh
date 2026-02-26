#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")"; pwd)"
BUILD_DIR="$PROJECT_DIR/build"
SAVER_NAME="LunchTalkSaver"
BUNDLE_ID="haoyu.LunchTalkSaver"

echo "🔨 Building LunchTalkSaver.saver using manual bundle creation..."

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
    <string>LunchTalkScreenSaverView</string>
</dict>
</plist>
EOF

echo "📝 Created Info.plist"

# Create a temporary Swift package
TMP_PKG_DIR="/tmp/LunchTalkSaverPkg"
rm -rf "$TMP_PKG_DIR"
mkdir -p "$TMP_PKG_DIR/Sources/LunchTalkSaver"

# Copy source files
cp "$PROJECT_DIR/AI_ScreenSaver/ScreenSaverPlugin.swift" "$TMP_PKG_DIR/Sources/LunchTalkSaver/"
cp "$PROJECT_DIR/AI_ScreenSaver/SessionStore.swift" "$TMP_PKG_DIR/Sources/LunchTalkSaver/"
cp "$PROJECT_DIR/AI_ScreenSaver/SaverContentView.swift" "$TMP_PKG_DIR/Sources/LunchTalkSaver/"

# Create Package.swift
cat > "$TMP_PKG_DIR/Package.swift" << 'PKGEOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LunchTalkSaver",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "LunchTalkSaver",
            type: .dynamic,
            targets: ["LunchTalkSaver"]
        )
    ],
    targets: [
        .target(
            name: "LunchTalkSaver",
            path: "Sources/LunchTalkSaver",
            linkerSettings: [
                .linkedFramework("ScreenSaver"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Combine")
            ]
        )
    ]
)
PKGEOF

echo "🔧 Compiling Swift package..."
cd "$TMP_PKG_DIR"
swift build -c release

if [ $? -eq 0 ]; then
    # Copy the built dylib
    DYLIB_PATH="$TMP_PKG_DIR/.build/release/libLunchTalkSaver.dylib"
    if [ -f "$DYLIB_PATH" ]; then
        cp "$DYLIB_PATH" "$BUILD_DIR/$SAVER_NAME.saver/Contents/MacOS/$SAVER_NAME"

        # Fix install name
        install_name_tool -id "@loader_path/$SAVER_NAME" "$BUILD_DIR/$SAVER_NAME.saver/Contents/MacOS/$SAVER_NAME"

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
        echo "❌ Built dylib not found at $DYLIB_PATH"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi
