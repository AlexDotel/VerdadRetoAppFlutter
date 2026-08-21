from pathlib import Path

from PIL import Image


root = Path(__file__).resolve().parents[1]
source = Image.open(
    root / "assets" / "branding" / "verdad-o-reto-logo-transparent.png"
).convert("RGBA")
bounds = source.getbbox()
if bounds is not None:
    source = source.crop(bounds)

res = root / "android" / "app" / "src" / "main" / "res"
density_sizes = {
    "mdpi": 160,
    "hdpi": 240,
    "xhdpi": 320,
    "xxhdpi": 480,
    "xxxhdpi": 640,
}


def splash(size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    image = source.copy()
    target = int(size * 0.78)
    image.thumbnail((target, target), Image.Resampling.LANCZOS)
    canvas.alpha_composite(
        image,
        ((size - image.width) // 2, (size - image.height) // 2),
    )
    return canvas


for density, size in density_sizes.items():
    directory = res / f"drawable-{density}"
    directory.mkdir(parents=True, exist_ok=True)
    splash(size).save(directory / "splash_logo.png", optimize=True)

