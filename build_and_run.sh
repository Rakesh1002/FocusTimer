#!/bin/bash

set -e  # Exit on error

# Build the app
swift build

# Create app bundle directory structure
APP_NAME="FocusTimer"
BUNDLE_DIR="$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Clean up previous bundle
rm -rf "$BUNDLE_DIR"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy the executable
cp .build/debug/FocusTimer "$MACOS_DIR/"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.example.FocusTimer</string>
    <key>CFBundleName</key>
    <string>FocusTimer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleExecutable</key>
    <string>FocusTimer</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF

# Make the executable... executable
chmod +x "$MACOS_DIR/FocusTimer"

echo "App bundle created at $BUNDLE_DIR"

# Kill any existing instances
pkill -x FocusTimer || true

# Wait a moment
sleep 1

# Run the app
open "$BUNDLE_DIR"

# Wait a moment to see any immediate errors
sleep 2

# Check if the app is running
if pgrep -x FocusTimer > /dev/null; then
    echo "App is running!"
else
    echo "App failed to start!"
    # Show the last few lines of system.log
    log show --predicate 'process == "FocusTimer"' --last 5m
fi
