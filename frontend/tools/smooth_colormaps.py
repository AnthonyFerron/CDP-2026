"""Lisse les dégradés des textures Kenney enregistrées en palette de 256 couleurs, sans dépendance externe.

Ces textures (colormap.png) rangent leurs couleurs en bandes verticales dégradées. En palette, chaque dégradé
n'a que quelques teintes : sur un mur agrandi quatre ou cinq fois, chaque marche devient une raie horizontale
bien visible. Le script lisse chaque dégradé de haut en bas, sans mélanger deux bandes voisines, et réécrit
l'image en couleurs vraies (RGBA). Une image déjà en couleurs vraies est laissée telle quelle.

    python tools/smooth_colormaps.py
"""

import struct
import zlib
from pathlib import Path

KENNEY = Path(__file__).resolve().parent.parent / "assets" / "models" / "kenney"
# Deux pixels voisins plus différents que cela appartiennent à deux bandes : on ne les mélange pas.
BAND_EDGE = 14
# Rayon du lissage, en pixels, de part et d'autre.
RADIUS = 10


def read_png(path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    offset, chunks = 8, {}
    idat = b""
    while offset < len(data):
        length, kind = struct.unpack(">I4s", data[offset:offset + 8])
        body = data[offset + 8:offset + 8 + length]
        if kind == b"IDAT":
            idat += body
        else:
            chunks.setdefault(kind, body)
        offset += 12 + length
    width, height, depth, color_type = struct.unpack(">IIBB", chunks[b"IHDR"][:10])
    return width, height, depth, color_type, chunks, zlib.decompress(idat)


def unfilter(raw, width, height, channels):
    stride = width * channels
    rows, previous, position = [], bytearray(stride), 0
    for _ in range(height):
        kind = raw[position]
        line = bytearray(raw[position + 1:position + 1 + stride])
        position += 1 + stride
        for i in range(stride):
            left = line[i - channels] if i >= channels else 0
            up = previous[i]
            corner = previous[i - channels] if i >= channels else 0
            if kind == 1:
                line[i] = (line[i] + left) & 255
            elif kind == 2:
                line[i] = (line[i] + up) & 255
            elif kind == 3:
                line[i] = (line[i] + (left + up) // 2) & 255
            elif kind == 4:
                p = left + up - corner
                pa, pb, pc = abs(p - left), abs(p - up), abs(p - corner)
                line[i] = (line[i] + (left if pa <= pb and pa <= pc else up if pb <= pc else corner)) & 255
        rows.append(line)
        previous = line
    return rows


def decode_palette(path):
    """Pixels RGBA d'une image en palette 8 bits, ou None si l'image n'est pas en palette."""
    width, height, depth, color_type, chunks, raw = read_png(path)
    if color_type != 3 or depth != 8:
        return None
    palette = chunks[b"PLTE"]
    alpha = chunks.get(b"tRNS", b"")
    rows = unfilter(raw, width, height, 1)
    pixels = []
    for row in rows:
        line = []
        for index in row:
            r, g, b = palette[index * 3:index * 3 + 3]
            line.append([r, g, b, alpha[index] if index < len(alpha) else 255])
        pixels.append(line)
    return width, height, pixels


def smooth(width, height, pixels):
    result = [[list(p) for p in row] for row in pixels]
    for x in range(width):
        column = [pixels[y][x] for y in range(height)]
        # Découpe la colonne en bandes, là où la couleur saute brusquement.
        start = 0
        for y in range(1, height + 1):
            edge = y == height or max(abs(column[y][c] - column[y - 1][c]) for c in range(4)) > BAND_EDGE
            if not edge:
                continue
            for row in range(start, y):
                low, high = max(start, row - RADIUS), min(y - 1, row + RADIUS)
                span = high - low + 1
                for c in range(3):
                    result[row][x][c] = round(sum(column[k][c] for k in range(low, high + 1)) / span)
            start = y
    return result


def write_png(path, width, height, pixels):
    raw = b"".join(b"\x00" + bytes(value for pixel in row for value in pixel) for row in pixels)

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def main():
    for path in sorted(KENNEY.glob("*/Textures/*.png")):
        decoded = decode_palette(path)
        if not decoded:
            continue
        width, height, pixels = decoded
        write_png(path, width, height, smooth(width, height, pixels))
        print(f"{path.parent.parent.name}/{path.name} : dégradés lissés")


if __name__ == "__main__":
    main()
