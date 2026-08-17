from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


root = Path(__file__).resolve().parents[1]
flutter_font = Path.home() / "develop" / "flutter" / "bin" / "cache" / "artifacts" / "material_fonts" / "materialicons-regular.otf"
font = ImageFont.truetype(str(flutter_font), 900)
glyph = chr(0xF0229)  # Flutter Icons.theater_comedy_rounded
probe = Image.new("RGBA", (1200, 1200), (0, 0, 0, 0))
draw = ImageDraw.Draw(probe)
bbox = draw.textbbox((0, 0), glyph, font=font)
source = Image.new("RGBA", (bbox[2] - bbox[0], bbox[3] - bbox[1]), (0, 0, 0, 0))
ImageDraw.Draw(source).text((-bbox[0], -bbox[1]), glyph, font=font, fill=(79, 115, 241, 255))


def fitted(size: int, scale: float) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    target = int(size * scale)
    symbol = source.copy()
    symbol.thumbnail((target, target), Image.Resampling.LANCZOS)
    x = (size - symbol.width) // 2
    y = (size - symbol.height) // 2
    canvas.alpha_composite(symbol, (x, y))
    return canvas


branding = root / "assets" / "branding"
branding.mkdir(parents=True, exist_ok=True)
fitted(1024, 0.78).save(branding / "impostor-mask.png")

res = root / "android" / "app" / "src" / "main" / "res"
foreground_sizes = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
legacy_sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}

for density, size in foreground_sizes.items():
    directory = res / f"drawable-{density}"
    directory.mkdir(parents=True, exist_ok=True)
    fitted(size, 0.66).save(directory / "impostor_foreground.png")

for density, size in legacy_sizes.items():
    directory = res / f"mipmap-{density}"
    directory.mkdir(parents=True, exist_ok=True)
    background = Image.new("RGBA", (size, size), (13, 16, 32, 255))
    background.alpha_composite(fitted(size, 0.68))
    background.save(directory / "impostor_launcher.png")

nodpi = res / "drawable-nodpi"
nodpi.mkdir(parents=True, exist_ok=True)
fitted(320, 0.72).save(nodpi / "splash_logo.png")
