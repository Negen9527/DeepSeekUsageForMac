#!/bin/bash
set -e

# DeepSeekUsageForMac Build Script
# Builds both the main app and widget extension, packages into .app bundle
# Usage: ./build.sh [--release]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_NAME="DeepSeekUsage"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

SDK=$(xcrun --show-sdk-path)
TARGET="arm64-apple-macosx14.0"
SWIFT_BASE="-sdk $SDK -target $TARGET -Osize"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
err()   { echo -e "${RED}[ERR]${NC} $1"; exit 1; }

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ==================== Fix CLT module map issue ====================
MODULEMAP_BAK="/Library/Developer/CommandLineTools/usr/include/swift/bridging.modulemap.bak"
MODULEMAP="/Library/Developer/CommandLineTools/usr/include/swift/bridging.modulemap"
if [ -f "$MODULEMAP" ] && [ -f "$MODULEMAP_BAK" ]; then
    info "Module map already fixed"
elif [ -f "$MODULEMAP" ]; then
    info "Fixing module map conflict..."
    osascript -e "do shell script \"mv '$MODULEMAP' '$MODULEMAP_BAK'\" with administrator privileges" 2>/dev/null || {
        err "Need admin privileges to fix module map. Run: sudo mv '$MODULEMAP' '$MODULEMAP_BAK'"
    }
    ok "Module map fixed"
fi

# ==================== Compile App ====================
info "Compiling main app..."
swiftc $SWIFT_BASE \
    -framework SwiftUI -framework AppKit -framework WidgetKit \
    -framework Foundation -framework Combine -framework Security \
    -parse-as-library \
    -module-name DeepSeekUsageApp \
    -o "$BUILD_DIR/app_executable" \
    "$SCRIPT_DIR/Shared/Constants/AppConstants.swift" \
    "$SCRIPT_DIR/Shared/Theme/AppTheme.swift" \
    "$SCRIPT_DIR/Shared/Models/WidgetSnapshot.swift" \
    "$SCRIPT_DIR/DeepSeekUsageApp/Services/KeychainService.swift" \
    "$SCRIPT_DIR/DeepSeekUsageApp/Services/DeepSeekAPIService.swift" \
    "$SCRIPT_DIR/DeepSeekUsageApp/Services/UsageTrackerService.swift" \
    "$SCRIPT_DIR/DeepSeekUsageApp/ViewModels/DashboardViewModel.swift" \
    "$SCRIPT_DIR/DeepSeekUsageApp/Views/ConfigPanelView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageApp/Views/MenuBarContentView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageApp/Views/DesktopWidgetView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/Components/CircularGaugeView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/Components/StatsCardView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/Components/UsageProgressBar.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/Components/TrendChartView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/Components/TrendLineChartView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/Components/AnimatedPieChartView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageApp/DeepSeekUsageApp.swift" \
    2>&1 || err "App compilation failed"
ok "App compiled"

# ==================== Compile Widget ====================
info "Compiling widget extension..."
swiftc $SWIFT_BASE \
    -framework SwiftUI -framework WidgetKit \
    -framework Foundation -framework Combine \
    -parse-as-library \
    -module-name DeepSeekUsageWidget \
    -o "$BUILD_DIR/widget_executable" \
    "$SCRIPT_DIR/Shared/Constants/AppConstants.swift" \
    "$SCRIPT_DIR/Shared/Theme/AppTheme.swift" \
    "$SCRIPT_DIR/Shared/Models/WidgetSnapshot.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/Components/CircularGaugeView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/Components/StatsCardView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/Components/UsageProgressBar.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/Components/TrendChartView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/Components/TrendLineChartView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/Components/AnimatedPieChartView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/SmallWidgetView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/MediumWidgetView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Views/LargeWidgetView.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/Provider.swift" \
    "$SCRIPT_DIR/DeepSeekUsageWidget/DeepSeekUsageWidget.swift" \
    2>&1 || err "Widget compilation failed"
ok "Widget compiled"

# ==================== Create App Bundle ====================
info "Creating app bundle..."

# Directory structure
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/PlugIns/DeepSeekUsageWidget.appex/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$APP_DIR/Contents/PlugIns/DeepSeekUsageWidget.appex/Contents/Resources"

# Copy executables
cp "$BUILD_DIR/app_executable" "$APP_DIR/Contents/MacOS/DeepSeekUsageApp"
cp "$BUILD_DIR/widget_executable" "$APP_DIR/Contents/PlugIns/DeepSeekUsageWidget.appex/Contents/MacOS/DeepSeekUsageWidgetExtension"
chmod +x "$APP_DIR/Contents/MacOS/DeepSeekUsageApp"
chmod +x "$APP_DIR/Contents/PlugIns/DeepSeekUsageWidget.appex/Contents/MacOS/DeepSeekUsageWidgetExtension"

# Copy assets
cp -r "$SCRIPT_DIR/DeepSeekUsageApp/Assets.xcassets" "$APP_DIR/Contents/Resources/" 2>/dev/null || true
cp -r "$SCRIPT_DIR/DeepSeekUsageWidget/Assets.xcassets" "$APP_DIR/Contents/PlugIns/DeepSeekUsageWidget.appex/Contents/Resources/" 2>/dev/null || true

# ==================== Create Info.plist (App) ====================
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>zh_CN</string>
	<key>CFBundleDisplayName</key>
	<string>DeepSeek 用量</string>
	<key>CFBundleExecutable</key>
	<string>DeepSeekUsageApp</string>
	<key>CFBundleIdentifier</key>
	<string>com.deepseekusage.app</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>DeepSeekUsage</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST

# ==================== Create Info.plist (Widget) ====================
cat > "$APP_DIR/Contents/PlugIns/DeepSeekUsageWidget.appex/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>zh_CN</string>
	<key>CFBundleDisplayName</key>
	<string>DeepSeek 用量</string>
	<key>CFBundleExecutable</key>
	<string>DeepSeekUsageWidgetExtension</string>
	<key>CFBundleIdentifier</key>
	<string>com.deepseekusage.app.widget</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>DeepSeekUsageWidget</string>
	<key>CFBundlePackageType</key>
	<string>XPC!</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.widgetkit-extension</string>
		<key>NSExtensionPrincipalClass</key>
		<string>DeepSeekUsageWidget.DeepSeekUsageWidget</string>
	</dict>
</dict>
</plist>
PLIST

# ==================== Code Sign ====================
info "Code signing..."
codesign --force --deep -s - --entitlements "$SCRIPT_DIR/DeepSeekUsageWidget.entitlements" "$APP_DIR/Contents/PlugIns/DeepSeekUsageWidget.appex" 2>&1 || err "Widget signing failed"
codesign --force --deep -s - --entitlements "$SCRIPT_DIR/DeepSeekUsageApp.entitlements" "$APP_DIR" 2>&1 || err "App signing failed"
ok "Code signed"

# ==================== Clean up ====================
rm -f "$BUILD_DIR/app_executable" "$BUILD_DIR/widget_executable"

# ==================== Summary ====================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Build Successful!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "App: ${CYAN}$APP_DIR${NC}"
echo -e "Size: $(du -sh "$APP_DIR" | cut -f1)"
echo ""
echo -e "To launch: ${CYAN}open '$APP_DIR'${NC}"
echo -e "Or double-click in Finder: ${CYAN}open '$BUILD_DIR'${NC}"
echo ""
echo -e "To install to /Applications:"
echo -e "  ${CYAN}cp -r '$APP_DIR' /Applications/${NC}"
