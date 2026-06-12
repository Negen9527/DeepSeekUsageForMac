#!/usr/bin/env python3
import os
import shutil
from PIL import Image, ImageDraw, ImageFont

ICON_DIR = "DeepSeekUsageApp/Assets.xcassets/AppIcon.appiconset"
OUTPUT_DIR = "build/icon.iconset"

# macOS icon sizes
sizes = [16, 32, 64, 128, 256, 512]

def create_icon(size, is_retina=False):
    actual_size = size * (2 if is_retina else 1)
    img = Image.new('RGBA', (actual_size, actual_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw rounded rectangle with gradient
    corner_radius = int(actual_size * 0.2)
    draw.rounded_rectangle([0, 0, actual_size, actual_size], corner_radius, fill=(15, 23, 30))
    
    # Add cyan border
    draw.rounded_rectangle([2, 2, actual_size-2, actual_size-2], corner_radius-1, outline=(0, 242, 255), width=2)
    
    # Draw "D" letter with glow
    font_size = int(actual_size * 0.55)
    try:
        font = ImageFont.truetype('/System/Library/Fonts/SFNSDisplay.ttf', font_size)
    except:
        font = ImageFont.load_default()
    
    text = "D"
    text_bbox = draw.textbbox((0, 0), text, font=font)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]
    x = (actual_size - text_width) // 2
    y = (actual_size - text_height) // 2 - int(actual_size * 0.05)
    
    # Glow effect
    for dx in [-2, -1, 0, 1, 2]:
        for dy in [-2, -1, 0, 1, 2]:
            draw.text((x + dx, y + dy), text, font=font, fill=(0, 242, 255, 40))
    
    draw.text((x, y), text, font=font, fill=(255, 255, 255))
    
    return img

# Create iconset directory
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Create all required icon files
for size in sizes:
    # Normal resolution
    img = create_icon(size, is_retina=False)
    img.save(f"{OUTPUT_DIR}/icon_{size}x{size}.png")
    
    # Retina resolution
    img2x = create_icon(size, is_retina=True)
    img2x.save(f"{OUTPUT_DIR}/icon_{size}x{size}@2x.png")

print(f"Created iconset in {OUTPUT_DIR}")
