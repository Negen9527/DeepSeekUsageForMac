#!/bin/bash

ICON_DIR="DeepSeekUsageApp/Assets.xcassets/AppIcon.appiconset"

# Create PNG icons using sips (macOS built-in image processing)
# We'll create simple gradient icons

create_icon() {
    local size=$1
    local scale=$2
    local filename="app_${size}x${size}@${scale}x.png"
    
    # Create a temporary SVG with gradient and DeepSeek cyan accent
    cat > /tmp/icon.svg << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#00f2ff;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#14202a;stop-opacity:1" />
    </linearGradient>
    <filter id="glow">
      <feGaussianBlur stdDeviation="2" result="coloredBlur"/>
      <feMerge>
        <feMergeNode in="coloredBlur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <rect width="${size}" height="${size}" rx="$(echo "${size} * 0.2" | bc)" fill="url(#grad)"/>
  <text x="50%" y="55%" font-family="Arial, sans-serif" font-size="$(echo "${size} * 0.5" | bc)" font-weight="bold" fill="white" text-anchor="middle" filter="url(#glow)">D</text>
</svg>
SVGEOF
    
    # Convert SVG to PNG
    rsvg-convert -o "$ICON_DIR/$filename" /tmp/icon.svg 2>/dev/null || \
    inkscape -o "$ICON_DIR/$filename" /tmp/icon.svg 2>/dev/null || \
    echo "Warning: Could not create $filename (requires rsvg-convert or inkscape)"
    
    rm /tmp/icon.svg
}

# Create icons for all required sizes
echo "Creating app icons..."

# 16x16
create_icon 16 1
create_icon 16 2

# 32x32
create_icon 32 1
create_icon 32 2

# 128x128
create_icon 128 1
create_icon 128 2

# 256x256
create_icon 256 1
create_icon 256 2

# 512x512
create_icon 512 1
create_icon 512 2

echo "Icons created in $ICON_DIR"
