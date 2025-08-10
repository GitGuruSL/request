#!/usr/bin/env python3
"""
Custom Adaptive Icon Generator for Request Marketplace
Creates adaptive icons with gradient arrow design
"""

from PIL import Image, ImageDraw
import os

# Adaptive icon size (Android requirement)
ADAPTIVE_SIZE = 108  # 108dp for adaptive icons
FOREGROUND_SIZE = 72  # Safe area for foreground (66% of total)

def create_gradient_background_adaptive(size, start_color, end_color):
    """Create a gradient background for adaptive icons"""
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

def create_adaptive_background():
    """Create adaptive icon background layer"""
    start_color = (91, 192, 222)   # Light blue/cyan
    end_color = (129, 199, 132)    # Light green
    return create_gradient_background_adaptive(ADAPTIVE_SIZE, start_color, end_color)

def create_adaptive_foreground():
    """Create adaptive icon foreground layer"""
    img = Image.new('RGBA', (ADAPTIVE_SIZE, ADAPTIVE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Calculate position for centered icon
    center_x = ADAPTIVE_SIZE // 2
    center_y = ADAPTIVE_SIZE // 2
    arrow_size = FOREGROUND_SIZE // 2
    
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
    
    # Add subtle shadow for depth
    shadow_offset = ADAPTIVE_SIZE // 50
    if shadow_offset > 0:
        # Draw arrow shadow slightly offset
        shadow_alpha = 30
        
        # Shadow shaft
        draw.rounded_rectangle([shaft_x1 + shadow_offset, shaft_y1 + shadow_offset, 
                               shaft_x2 + shadow_offset, shaft_y2 + shadow_offset], 
                              shaft_width // 4, fill=(0, 0, 0, shadow_alpha))
        
        # Shadow head
        shadow_top = (center_x + shadow_offset, head_y - arrow_head_size // 2 + shadow_offset)
        shadow_left = (center_x - arrow_head_size // 2 + shadow_offset, head_y + arrow_head_size // 4 + shadow_offset)
        shadow_right = (center_x + arrow_head_size // 2 + shadow_offset, head_y + arrow_head_size // 4 + shadow_offset)
        
        draw.polygon([shadow_top, shadow_left, shadow_right], fill=(0, 0, 0, shadow_alpha))
    
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
    print("Generating custom adaptive icons...")
    generate_adaptive_icons()
    print("Custom adaptive icon generation complete!")
