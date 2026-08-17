from pathlib import Path
import sys

from PIL import Image


root = Path(__file__).resolve().parents[1]
source = Image.open(sys.argv[1]).convert("RGBA")


def square(size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (13, 16, 32, 255))
    image = source.copy()
    image.thumbnail((size, size), Image.Resampling.LANCZOS)
    canvas.alpha_composite(image, ((size - image.width) // 2, (size - image.height) // 2))
    return canvas


def foreground(size: int, scale: float) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    target = int(size * scale)
    image = source.copy()
    image.thumbnail((target, target), Image.Resampling.LANCZOS)
    canvas.alpha_composite(image, ((size - image.width) // 2, (size - image.height) // 2))
    return canvas


branding = root / "assets" / "branding"
branding.mkdir(parents=True, exist_ok=True)
square(1024).save(branding / "impostor-mask.png")

res = root / "android" / "app" / "src" / "main" / "res"
foreground_sizes = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
legacy_sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}

for density, size in foreground_sizes.items():
    foreground(size, 0.94).save(res / f"drawable-{density}" / "impostor_foreground.png")

for density, size in legacy_sizes.items():
    square(size).save(res / f"mipmap-{density}" / "impostor_launcher.png")

square(320).save(res / "drawable-nodpi" / "splash_logo.png")
