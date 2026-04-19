#!/bin/bash

# Settings
APP_NAME="Bublik"
SCHEME_NAME="Bublik" # usually the same as the app name
TMP_DIR="./tmp" # path relative to the project root
BUILD_DIR="$TMP_DIR/build_output"
DMG_DIR="$TMP_DIR/dmg_folder"
DMG_PATH="$TMP_DIR/Bublik_Installer.dmg"

echo "Build started..."

# Remove previous build artifacts
rm -rf "$TMP_DIR"
rm -rf ~/Library/Developer/Xcode/DerivedData/$APP_NAME-*

# Increment the build number
xcrun agvtool next-version -all

# Build in Release mode
xcodebuild -scheme "$SCHEME_NAME" \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR" \
           clean build

# Path to the compiled .app file
APP_PATH=$(find "$BUILD_DIR" -name "$APP_NAME.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "Error: Failed to find the compiled .app"
    exit 1
fi

echo "Preparing DMG folder..."
mkdir -p "$DMG_DIR"

# Copy the application to the DMG folder
cp -R "$APP_PATH" "$DMG_DIR/"

# Create a symlink to /Applications
ln -s /Applications "$DMG_DIR/Applications"

# Create the README FIRST.txt file
cat <<EOF > "$DMG_DIR/README FIRST.txt"
INSTALLATION INSTRUCTIONS:

1. Drag $APP_NAME.app to the Applications folder.
2. Open Terminal.
3. Copy and execute the following command to remove quarantine attributes:
   xattr -cr /Applications/$APP_NAME.app
4. Run the application.

This is necessary because the application is built without a paid developer certificate.
EOF

# Create the DMG
echo "Creating DMG image..."
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_DIR" -ov -format UDZO "$DMG_PATH"

echo "Done! File $DMG_PATH created."

# TODO Clean up temporary folders (optional)
# rm -rf "$DMG_DIR"
# rm -rf "$BUILD_DIR"