#!/usr/bin/env python3
from __future__ import annotations

import struct
import sys
from collections import deque
from pathlib import Path

from PIL import Image


FRAME_COUNT = 8
TOMATO_GREEN = (73, 145, 88)


def remove_background(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size

    def is_background(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        return a > 0 and r > 232 and g > 222 and b > 205 and max(r, g, b) - min(r, g, b) < 48

    visited = set()
    queue: deque[tuple[int, int]] = deque()
    for x in range(width):
        for y in (0, height - 1):
            if is_background(x, y):
                queue.append((x, y))
                visited.add((x, y))
    for y in range(height):
        for x in (0, width - 1):
            if is_background(x, y) and (x, y) not in visited:
                queue.append((x, y))
                visited.add((x, y))

    while queue:
        x, y = queue.popleft()
        r, g, b, _ = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in visited and is_background(nx, ny):
                visited.add((nx, ny))
                queue.append((nx, ny))

    keep_largest_component(rgba)
    return rgba


def keep_largest_component(image: Image.Image) -> None:
    pixels = image.load()
    width, height = image.size
    seen: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []
    for start_y in range(height):
        for start_x in range(width):
            if (start_x, start_y) in seen or pixels[start_x, start_y][3] == 0:
                continue

            queue: deque[tuple[int, int]] = deque([(start_x, start_y)])
            seen.add((start_x, start_y))
            component: list[tuple[int, int]] = []
            while queue:
                x, y = queue.popleft()
                component.append((x, y))
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in seen and pixels[nx, ny][3] > 0:
                        seen.add((nx, ny))
                        queue.append((nx, ny))
            components.append(component)

    if not components:
        return
    largest = max(components, key=len)
    keep = set(largest)
    for component in components:
        if component is largest:
            continue
        for x, y in component:
            if (x, y) not in keep:
                r, g, b, _ = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)


def make_green_variant(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            is_tomato_body = r > 130 and r > g * 1.35 and r > b * 1.22
            if is_tomato_body:
                shade = max(0.55, min(1.18, (0.299 * r + 0.587 * g + 0.114 * b) / 150))
                pixels[x, y] = (
                    min(255, round(TOMATO_GREEN[0] * shade)),
                    min(255, round(TOMATO_GREEN[1] * shade)),
                    min(255, round(TOMATO_GREEN[2] * shade)),
                    a,
                )
    return rgba


def normalize_frame(tile: Image.Image, size: int = 512) -> Image.Image:
    transparent = remove_background(tile)
    bbox = transparent.getbbox()
    if not bbox:
        return Image.new("RGBA", (size, size), (0, 0, 0, 0))

    cropped = transparent.crop(bbox)
    max_width = int(size * 0.88)
    max_height = int(size * 0.82)
    scale = min(max_width / cropped.width, max_height / cropped.height)
    resized = cropped.resize((round(cropped.width * scale), round(cropped.height * scale)), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - resized.width) // 2
    y = size - resized.height - int(size * 0.06)
    canvas.alpha_composite(resized, (x, y))
    return canvas


def split_frames(sheet_path: Path, frame_dir: Path) -> list[Image.Image]:
    frame_dir.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(sheet_path).convert("RGBA")
    width, height = sheet.size
    frames: list[Image.Image] = []
    base_width = width / FRAME_COUNT
    padding = round(base_width * 0.14)
    for index in range(FRAME_COUNT):
        left = max(0, round(width * index / FRAME_COUNT) - padding)
        right = min(width, round(width * (index + 1) / FRAME_COUNT) + padding)
        tile = sheet.crop((left, 0, right, height))
        frame = normalize_frame(tile)
        green = make_green_variant(frame)
        frame.save(frame_dir / f"frame_{index:02d}.png")
        green.save(frame_dir / f"frame_{index:02d}_green.png")
        frames.append(frame)
    return frames


def write_gif(frames: list[Image.Image], gif_path: Path) -> None:
    gif_path.parent.mkdir(parents=True, exist_ok=True)
    background = Image.new("RGBA", frames[0].size, (255, 248, 241, 255))
    gif_frames = []
    for frame in frames:
        composed = background.copy()
        composed.alpha_composite(frame)
        gif_frames.append(composed.convert("P", palette=Image.Palette.ADAPTIVE))
    gif_frames[0].save(
        gif_path,
        save_all=True,
        append_images=gif_frames[1:],
        duration=130,
        loop=0,
        disposal=2,
    )


def make_logo(frame: Image.Image, logo_path: Path, size: int = 1024) -> Image.Image:
    logo_path.parent.mkdir(parents=True, exist_ok=True)
    logo = Image.new("RGBA", (size, size), (255, 247, 239, 255))
    mask = Image.new("L", (size, size), 0)
    rounded = Image.new("RGBA", (size, size), (255, 247, 239, 255))
    # Use Pillow's rounded rectangle through ImageDraw only here to avoid extra app icon artifacts.
    from PIL import ImageDraw

    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size, size), radius=220, fill=255)
    character = frame.resize((860, 860), Image.Resampling.LANCZOS)
    rounded.alpha_composite(character, ((size - 860) // 2, 92))
    logo = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    logo.alpha_composite(rounded)
    logo.putalpha(mask)
    logo.save(logo_path)
    return logo


def write_icns(logo: Image.Image, icns_path: Path) -> None:
    icon_specs = [
        ("icp4", 16),
        ("ic11", 32),
        ("icp5", 32),
        ("ic12", 64),
        ("ic07", 128),
        ("ic13", 256),
        ("ic08", 256),
        ("ic14", 512),
        ("ic09", 512),
        ("ic10", 1024),
    ]
    entries = bytearray()
    for icon_type, size in icon_specs:
        image = logo.resize((size, size), Image.Resampling.LANCZOS)
        tmp = icns_path.with_suffix(f".{icon_type}.png")
        image.save(tmp)
        data = tmp.read_bytes()
        tmp.unlink()
        entries.extend(icon_type.encode("ascii"))
        entries.extend(struct.pack(">I", len(data) + 8))
        entries.extend(data)
    icns_path.write_bytes(b"icns" + struct.pack(">I", len(entries) + 8) + bytes(entries))


def main() -> int:
    if len(sys.argv) != 6:
        print("usage: prepare_tomato_sprite.py SHEET FRAME_DIR GIF LOGO ICNS", file=sys.stderr)
        return 2

    sheet_path = Path(sys.argv[1])
    frame_dir = Path(sys.argv[2])
    gif_path = Path(sys.argv[3])
    logo_path = Path(sys.argv[4])
    icns_path = Path(sys.argv[5])

    frames = split_frames(sheet_path, frame_dir)
    write_gif(frames, gif_path)
    logo = make_logo(frames[0], logo_path)
    write_icns(logo, icns_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
