#!/usr/bin/env python3
"""
Custom App Icon Generator for Request Marketplace
Creates icons based on the provided gradient arrow design
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

def create_gradient_background(size, start_color, end_color):
    """Create a gradient background"""
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    for y in range(size):
        # Calculate the blend ratio (0 to 1)
        ratio = y / size
        
        # Interpolate between colors
        r = int(start_color[0] * (1 - ratio) + end_color[0] * ratio)
        g = int(start_color[1] * (1 - ratio) + end_color[1] * ratio)
        b = int(start_color[2] * (1 - ratio) + end_color[2] * ratio)
        
        # Draw horizontal line with interpolated color
        for x in range(size):
            image.putpixel((x, y), (r, g, b, 255))
    
    return image

def create_custom_marketplace_icon(size):
    """Create a marketplace icon based on the provided design"""
    # Create gradient background (cyan to green)
    start_color = (91, 192, 222)   # Light blue/cyan
    end_color = (129, 199, 132)    # Light green
    
    img = create_gradient_background(size, start_color, end_color)
    draw = ImageDraw.Draw(img)
    
    # Apply rounded corners
    corner_radius = size // 6
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, size, size], corner_radius, fill=255)
    
    # Apply mask to create rounded corners
    rounded_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    for x in range(size):
        for y in range(size):
            if mask.getpixel((x, y)) > 0:
                rounded_img.putpixel((x, y), img.getpixel((x, y)))
    
    draw = ImageDraw.Draw(rounded_img)
    
    # Create the upward arrow
    center_x = size // 2
    center_y = size // 2
    arrow_size = size // 2.5
    
    # Arrow shaft (vertical rectangle)
    shaft_width = arrow_size // 4
    shaft_height = arrow_size // 1.5
    shaft_x1 = center_x - shaft_width // 2
    shaft_y1 = center_y + arrow_size // 6
    shaft_x2 = center_x + shaft_width // 2
    shaft_y2 = shaft_y1 + shaft_height
    
    draw.rounded_rectangle([shaft_x1, shaft_y1, shaft_x2, shaft_y2], 
                          shaft_width // 4, fill='white')
    
    # Arrow head (triangle)
    arrow_head_size = arrow_size // 2
    head_y = center_y - arrow_size // 4
    
    # Triangle points
    top_point = (center_x, head_y - arrow_head_size // 2)
    left_point = (center_x - arrow_head_size // 2, head_y + arrow_head_size // 4)
    right_point = (center_x + arrow_head_size // 2, head_y + arrow_head_size // 4)
    
    draw.polygon([top_point, left_point, right_point], fill='white')
    
    # Add a subtle shadow/depth effect
    shadow_offset = size // 40
    if shadow_offset > 0:
        # Draw arrow shadow slightly offset
        shadow_alpha = 50
        shadow_color = (0, 0, 0, shadow_alpha)
        
        # Shadow shaft
        draw.rounded_rectangle([shaft_x1 + shadow_offset, shaft_y1 + shadow_offset, 
                               shaft_x2 + shadow_offset, shaft_y2 + shadow_offset], 
                              shaft_width // 4, fill=(0, 0, 0, shadow_alpha))
        
        # Shadow head
        shadow_top = (center_x + shadow_offset, head_y - arrow_head_size // 2 + shadow_offset)
        shadow_left = (center_x - arrow_head_size // 2 + shadow_offset, head_y + arrow_head_size // 4 + shadow_offset)
        shadow_right = (center_x + arrow_head_size // 2 + shadow_offset, head_y + arrow_head_size // 4 + shadow_offset)
        
        draw.polygon([shadow_top, shadow_left, shadow_right], fill=(0, 0, 0, shadow_alpha))
    
    return rounded_img

def generate_android_icons():
    """Generate Android app icons for all densities"""
    base_path = "android/app/src/main/res"
    
    for folder, size in ANDROID_SIZES.items():
        # Create directory if it doesn't exist
        icon_dir = os.path.join(base_path, folder)
        os.makedirs(icon_dir, exist_ok=True)
        
        # Generate icon
        icon = create_custom_marketplace_icon(size)
        
        # Save icon
        icon_path = os.path.join(icon_dir, "ic_launcher.png")
        icon.save(icon_path, "PNG")
        print(f"Generated: {icon_path}")

if __name__ == "__main__":
    print("Generating custom Request Marketplace app icons...")
    generate_android_icons()
    print("Custom icon generation complete!")
