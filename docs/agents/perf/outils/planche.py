# Planche de comparaison : planche.py <sortie.png> <boîte x0,y0,x1,y1> <image> [image...]
import sys
from PIL import Image, ImageDraw
out, box = sys.argv[1], tuple(int(v) for v in sys.argv[2].split(","))
tiles = []
for path in sys.argv[3:]:
    im = Image.open(path).convert("RGB").crop(box)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 260, 16), fill=(0, 0, 0))
    d.text((3, 2), path.split("/")[-1], fill=(255, 255, 0))
    tiles.append(im)
w, h = tiles[0].size
sheet = Image.new("RGB", (w, h * len(tiles)))
for i, t in enumerate(tiles):
    sheet.paste(t, (0, i * h))
sheet.save(out)
