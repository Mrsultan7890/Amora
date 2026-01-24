from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import math

def create_brand_icon(size, filename):
    """Create brand-level icon like Tinder/Bumble quality"""
    
    # Brand colors - premium feel
    brand_gradient = [
        (255, 45, 85),    # Vibrant pink (like Tinder)
        (255, 20, 147),   # Deep pink
        (138, 43, 226),   # Blue violet
        (75, 0, 130)      # Indigo
    ]
    
    # Create premium background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    # Multi-layer gradient for depth
    for layer in range(3):
        gradient_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        
        for y in range(size):
            for x in range(size):
                # Distance from center
                center = size // 2
                dx = x - center
                dy = y - center
                distance = math.sqrt(dx*dx + dy*dy)
                max_dist = center * 1.2
                
                if distance < max_dist:
                    # Smooth radial gradient
                    ratio = distance / max_dist
                    
                    # Color interpolation
                    if ratio < 0.33:
                        t = ratio / 0.33
                        color = [
                            int(brand_gradient[0][i] * (1-t) + brand_gradient[1][i] * t)
                            for i in range(3)
                        ]
                    elif ratio < 0.66:
                        t = (ratio - 0.33) / 0.33
                        color = [
                            int(brand_gradient[1][i] * (1-t) + brand_gradient[2][i] * t)
                            for i in range(3)
                        ]
                    else:
                        t = (ratio - 0.66) / 0.34
                        color = [
                            int(brand_gradient[2][i] * (1-t) + brand_gradient[3][i] * t)
                            for i in range(3)
                        ]
                    
                    # Add layer-specific effects
                    alpha = max(0, 255 - int(ratio * 100) - layer * 20)
                    gradient_img.putpixel((x, y), (*color, alpha))
        
        # Blend layers
        if layer == 0:
            img = gradient_img
        else:
            img = Image.alpha_composite(img, gradient_img)
    
    # Create perfect circle mask
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    
    # Anti-aliased circle
    center = size // 2
    radius = center - size // 25  # Small margin
    
    # Smooth circle with anti-aliasing
    for y in range(size):
        for x in range(size):
            dx = x - center
            dy = y - center
            distance = math.sqrt(dx*dx + dy*dy)
            
            if distance <= radius:
                if distance > radius - 2:
                    # Anti-aliasing edge
                    alpha = int(255 * (radius - distance) / 2)
                else:
                    alpha = 255
                mask.putpixel((x, y), alpha)
    
    # Apply mask
    img.putalpha(mask)
    
    # Create brand symbol - Modern minimalist heart
    draw = ImageDraw.Draw(img)
    
    # Heart dimensions
    heart_size = size * 0.35
    center_x, center_y = size // 2, size // 2 + size // 20
    
    # Perfect heart shape using mathematical curve
    def heart_equation(t):
        x = 16 * math.sin(t)**3
        y = 13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t)
        return x, -y  # Flip Y
    
    # Generate heart points
    heart_points = []
    for i in range(360):
        t = math.radians(i)
        x, y = heart_equation(t)
        # Scale and position
        px = center_x + (x * heart_size / 32)
        py = center_y + (y * heart_size / 32)
        heart_points.append((px, py))
    
    # Draw heart with gradient fill
    heart_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    heart_draw = ImageDraw.Draw(heart_img)
    
    # White heart with subtle gradient
    heart_draw.polygon(heart_points, fill=(255, 255, 255, 240))
    
    # Add inner glow
    glow_points = []
    for i in range(360):
        t = math.radians(i)
        x, y = heart_equation(t)
        px = center_x + (x * heart_size * 0.8 / 32)
        py = center_y + (y * heart_size * 0.8 / 32)
        glow_points.append((px, py))
    
    heart_draw.polygon(glow_points, fill=(255, 255, 255, 100))
    
    # Blend heart
    img = Image.alpha_composite(img, heart_img)
    
    # Add premium shine effect
    shine = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shine_draw = ImageDraw.Draw(shine)
    
    # Top-left shine (like premium apps)
    shine_x = center_x - size // 3
    shine_y = center_y - size // 3
    shine_w = size // 2
    shine_h = size // 3
    
    # Elliptical shine
    for i in range(20):
        alpha = max(0, 40 - i * 2)
        shine_draw.ellipse([
            shine_x - i, shine_y - i,
            shine_x + shine_w + i, shine_y + shine_h + i
        ], fill=(255, 255, 255, alpha))
    
    # Apply shine
    img = Image.alpha_composite(img, shine)
    
    # Add subtle shadow for depth
    shadow = Image.new('RGBA', (size + 10, size + 10), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse([2, 8, size + 8, size + 16], fill=(0, 0, 0, 30))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=6))
    
    # Final composition
    final = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    final.paste(shadow, (-5, -5), shadow)
    final = Image.alpha_composite(final, img)
    
    # Save with maximum quality
    final.save(filename, 'PNG', quality=100, optimize=True, dpi=(300, 300))
    print(f"💎 Created brand-level {filename} ({size}x{size})")

# Create brand icons
sizes = {
    'app_icon.png': 1024,  # High res for store
    'app_icon_foreground.png': 432,
    '../android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    '../android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    '../android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    '../android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    '../android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
}

print("💎 Creating BRAND-LEVEL Amora icons...")
print("🔥 Tinder/Bumble quality...")

for filename, size in sizes.items():
    create_brand_icon(size, filename)

print("✨ BRAND ICONS COMPLETE!")
print("🚀 Ready for billion-dollar app!")