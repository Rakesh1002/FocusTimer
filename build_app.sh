#!/bin/bash

# Build the Swift package
swift build -c release

# Create the app bundle structure
APP_NAME="FocusTimer"
BUNDLE_DIR="$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Clean up any existing bundle
rm -rf "$BUNDLE_DIR"

# Create directories
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy the binary
cp .build/release/FocusTimer "$MACOS_DIR/"

# Generate icons
./generate_icons.sh

# Copy the icon to both bundle and DMG resources
cp icon.icns "$RESOURCES_DIR/AppIcon.icns"
cp icon.icns AppIcon.icns

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>FocusTimer</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.focustimer</string>
    <key>CFBundleName</key>
    <string>FocusTimer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright 2024. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# Copy entitlements file
cp FocusTimer.entitlements "$CONTENTS_DIR/"

# Clean up old DMG if it exists
rm -f "$APP_NAME.dmg"

# Create a DMG for distribution
create-dmg \
  --volname "$APP_NAME" \
  --volicon "AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "$APP_NAME.app" 175 120 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 425 120 \
  "$APP_NAME.dmg" \
  "$APP_NAME.app"

# Clean up temporary files
rm -f AppIcon.icns icon.icns
