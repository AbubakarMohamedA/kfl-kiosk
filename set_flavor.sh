#!/bin/bash

# Configuration script for macOS and Windows Flutter Flavors
# Usage: ./set_flavor.sh <superadmin|manager|staff|warehouse|kiosk>

FLAVOR=$1

if [ -z "$FLAVOR" ]; then
    echo "Usage: ./set_flavor.sh <superadmin|manager|staff|warehouse|kiosk>"
    exit 1
fi

case "$FLAVOR" in
  "superadmin")
    APP_NAME="SSS Admin"
    APP_ID="com.example.kflkiosk.superadmin"
    ;;
  "manager")
    APP_NAME="SSS Manager"
    APP_ID="com.example.kflkiosk.manager"
    ;;
  "staff")
    APP_NAME="SSS Staff"
    APP_ID="com.example.kflkiosk.staff"
    ;;
  "warehouse")
    APP_NAME="SSS Warehouse"
    APP_ID="com.example.kflkiosk.warehouse"
    ;;
  "dashboard")
    APP_NAME="SSS Dashboard"
    APP_ID="com.example.kflkiosk.dashboard"
    ;;
  "kiosk")
    APP_NAME="SSS Kiosk"
    APP_ID="com.example.kflkiosk.kiosk"
    ;;
  *)
    echo "Unknown flavor: $FLAVOR"
    echo "Usage: ./set_flavor.sh <superadmin|manager|staff|warehouse|kiosk|dashboard>"
    exit 1
    ;;
esac

echo "========================================"
echo " Setting Flavor: $APP_NAME"
echo " Bundle ID:      $APP_ID"
echo "========================================"

# --- macOS Configuration ---
if [ -f "macos/Runner/Configs/AppInfo.xcconfig" ]; then
    # Cross-platform sed compatible with both Linux (GNU) and macOS (BSD)
    sed -i.bak -e "s/^PRODUCT_NAME = .*/PRODUCT_NAME = $APP_NAME/" macos/Runner/Configs/AppInfo.xcconfig
    sed -i.bak -e "s/^PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = $APP_ID/" macos/Runner/Configs/AppInfo.xcconfig
    rm -f macos/Runner/Configs/AppInfo.xcconfig.bak
    echo "✔ Updated macOS AppInfo.xcconfig"
else
    echo "⚠ macOS Runner config not found."
fi

# --- iOS Configuration ---
if [ -d "ios/Runner.xcodeproj" ]; then
    # Update project.pbxproj PRODUCT_BUNDLE_IDENTIFIER
    sed -i.bak -E "s/PRODUCT_BUNDLE_IDENTIFIER = com\.example\.kflkiosk[^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $APP_ID;/g" ios/Runner.xcodeproj/project.pbxproj
    # Fix the RunnerTests target bundle id so it remains valid
    sed -i.bak -E "s/PRODUCT_BUNDLE_IDENTIFIER = $APP_ID\.RunnerTests;/PRODUCT_BUNDLE_IDENTIFIER = com.example.kflkiosk.RunnerTests;/g" ios/Runner.xcodeproj/project.pbxproj
    rm -f ios/Runner.xcodeproj/project.pbxproj.bak
    
    # Update Info.plist CFBundleDisplayName
    sed -i.bak -e "/<key>CFBundleDisplayName<\/key>/{n;s/<string>.*<\/string>/<string>$APP_NAME<\/string>/;}" ios/Runner/Info.plist
    sed -i.bak -e "/<key>CFBundleName<\/key>/{n;s/<string>.*<\/string>/<string>$APP_NAME<\/string>/;}" ios/Runner/Info.plist
    rm -f ios/Runner/Info.plist.bak
    
    echo "✔ Updated iOS project.pbxproj and Info.plist"
else
    echo "⚠ iOS project not found."
fi

# Map flavor to correct entry point
case "$FLAVOR" in
  "superadmin")
    ENTRY_FILE="lib/main_superadmin.dart"
    ;;
  "kiosk")
    ENTRY_FILE="lib/main_terminal.dart"
    ;;
  "dashboard")
    ENTRY_FILE="lib/main_dashboard.dart"
    ;;
  "manager")
    ENTRY_FILE="lib/main_branch.dart"
    ;;
  *)
    ENTRY_FILE="lib/main_${FLAVOR}.dart"
    ;;
esac

# Provide instructions on what to run next
echo ""
echo "Flavor applied! You can now run or build your app."
echo ""
echo "To run on macOS / iOS:"
echo "  flutter run -d macos -t $ENTRY_FILE"
echo "  flutter run -d ios -t $ENTRY_FILE"
echo ""
echo "To build for macOS / iOS:"
echo "  flutter build macos -t $ENTRY_FILE"
echo "  flutter build ipa -t $ENTRY_FILE"
echo ""
echo "(Note: For Windows and Linux, just use: export FLAVOR=$FLAVOR && flutter run -d [windows|linux] -t $ENTRY_FILE)"
echo "========================================"
