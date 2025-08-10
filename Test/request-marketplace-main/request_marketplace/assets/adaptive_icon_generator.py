#!/usr/bin/env python3
"""
Adaptive Icon Generator for Request Marketplace
Creates adaptive icons with foreground and background layers
"""

from PIL import Image, ImageDraw
import os

# Adaptive icon size (Android requirement)
ADAPTIVE_SIZE = 108  # 108dp for adaptive icons
FOREGROUND_SIZE = 72  # Safe area for foreground (66% of total)

def create_adaptive_background():
    """Create adaptive icon background layer"""
    img = Image.new('RGBA', (ADAPTIVE_SIZE, ADAPTIVE_SIZE), (103, 80, 164))  # #6750A4
    return img

def create_adaptive_foreground():
    """Create adaptive icon foreground layer"""
    img = Image.new('RGBA', (ADAPTIVE_SIZE, ADAPTIVE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Calculate position for centered icon
    center = ADAPTIVE_SIZE // 2
    
    # Shopping bag
    bag_size = FOREGROUND_SIZE // 2
    bag_x = center - bag_size // 2
    bag_y = center - bag_size // 4
    
    # Bag body
    draw.rounded_rectangle([
        bag_x, bag_y + bag_size // 4,
        bag_x + bag_size, bag_y + bag_size
    ], bag_size // 8, fill='white')
    
    # Bag handles
    handle_width = bag_size // 6
    handle_height = bag_size // 3
    
    # Left handle
    draw.ellipse([
        bag_x + bag_size // 4 - handle_width // 2, bag_y,
        bag_x + bag_size // 4 + handle_width // 2, bag_y + handle_height
    ], outline='white', width=ADAPTIVE_SIZE // 25)
    
    # Right handle
    draw.ellipse([
        bag_x + 3 * bag_size // 4 - handle_width // 2, bag_y,
        bag_x + 3 * bag_size // 4 + handle_width // 2, bag_y + handle_height
    ], outline='white', width=ADAPTIVE_SIZE // 25)
    
    # Location pin
    pin_size = FOREGROUND_SIZE // 6
    pin_x = center + bag_size // 3
    pin_y = center - bag_size // 4
    
    # Pin circle
    draw.ellipse([
        pin_x - pin_size // 2, pin_y - pin_size // 2,
        pin_x + pin_size // 2, pin_y + pin_size // 2
    ], fill='#FDD835')
    
    # Pin point
    draw.polygon([
        (pin_x, pin_y + pin_size // 2),
        (pin_x - pin_size // 4, pin_y),
        (pin_x + pin_size // 4, pin_y)
    ], fill='#FDD835')
    
    return img

def generate_adaptive_icons():
    """Generate adaptive icons for Android"""
    densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']
    scale_factors = [1, 1.5, 2, 3, 4]
    
    for density, scale in zip(densities, scale_factors):
        folder = f"mipmap-{density}"
        size = int(ADAPTIVE_SIZE * scale)
        
        # Create directory
        icon_dir = os.path.join("android/app/src/main/res", folder)
        os.makedirs(icon_dir, exist_ok=True)
        
        # Generate background
        bg = create_adaptive_background()
        bg_resized = bg.resize((size, size), Image.Resampling.LANCZOS)
        bg_path = os.path.join(icon_dir, "ic_launcher_background.png")
        bg_resized.save(bg_path, "PNG")
        
        # Generate foreground
        fg = create_adaptive_foreground()
        fg_resized = fg.resize((size, size), Image.Resampling.LANCZOS)
        fg_path = os.path.join(icon_dir, "ic_launcher_foreground.png")
        fg_resized.save(fg_path, "PNG")
        
        print(f"Generated adaptive icons for {density}: background and foreground")

if __name__ == "__main__":
    print("Generating adaptive icons...")
    generate_adaptive_icons()
    print("Adaptive icon generation complete!")
