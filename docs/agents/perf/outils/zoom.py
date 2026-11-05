# Agrandissement contrasté d'une zone : zoom.py <sortie> <x0,y0,x1,y1> <images...>
import sys
from PIL import Image, ImageEnhance, ImageDraw
out, box = sys.argv[1], tuple(int(v) for v in sys.argv[2].split(","))
tiles = []
for n in sys.argv[3:]:
    im = Image.open(n).convert("RGB").crop(box)
    im = ImageEnhance.Contrast(im).enhance(3.0)
    im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
    ImageDraw.Draw(im).text((4, 4), n.split("/")[-1], fill=(255, 255, 0))
    tiles.append(im)
w, h = tiles[0].size
sheet = Image.new("RGB", (w, h * len(tiles)))
for i, t in enumerate(tiles): sheet.paste(t, (0, i * h))
sheet.save(out)
