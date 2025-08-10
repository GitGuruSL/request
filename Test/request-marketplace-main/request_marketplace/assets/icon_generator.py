#!/usr/bin/env python3
"""
App Icon Generator for Request Marketplace
Creates a marketplace-themed icon with shopping bag and location pin
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Icon sizes for Android
ANDROID_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192
}

def create_marketplace_icon(size):
    """Create a marketplace-themed app icon"""
    # Create canvas
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background color - Material You primary
    bg_color = (103, 80, 164)  # #6750A4
    
    # Draw rounded rectangle background
    corner_radius = size // 6
    draw.rounded_rectangle([0, 0, size, size], corner_radius, fill=bg_color)
    
    # Icon elements
    center = size // 2
    
    # Draw shopping bag
    bag_size = size // 3
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
    ], outline='white', width=size // 20)
    
    # Right handle
    draw.ellipse([
        bag_x + 3 * bag_size // 4 - handle_width // 2, bag_y,
        bag_x + 3 * bag_size // 4 + handle_width // 2, bag_y + handle_height
    ], outline='white', width=size // 20)
    
    # Add small location pin (marketplace indicator)
    pin_size = size // 8
    pin_x = center + bag_size // 3
    pin_y = center - bag_size // 4
    
    # Pin circle
    draw.ellipse([
        pin_x - pin_size // 2, pin_y - pin_size // 2,
        pin_x + pin_size // 2, pin_y + pin_size // 2
    ], fill='#FDD835')  # Material Yellow
    
    # Pin point
    draw.polygon([
        (pin_x, pin_y + pin_size // 2),
        (pin_x - pin_size // 4, pin_y),
        (pin_x + pin_size // 4, pin_y)
    ], fill='#FDD835')
    
    return img

def generate_android_icons():
    """Generate Android app icons for all densities"""
    base_path = "android/app/src/main/res"
    
    for folder, size in ANDROID_SIZES.items():
        # Create directory if it doesn't exist
        icon_dir = os.path.join(base_path, folder)
        os.makedirs(icon_dir, exist_ok=True)
        
        # Generate icon
        icon = create_marketplace_icon(size)
        
        # Save icon
        icon_path = os.path.join(icon_dir, "ic_launcher.png")
        icon.save(icon_path, "PNG")
        print(f"Generated: {icon_path}")

if __name__ == "__main__":
    print("Generating Request Marketplace app icons...")
    generate_android_icons()
    print("Icon generation complete!")
