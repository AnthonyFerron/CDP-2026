"""Planche avant / après : planche.py <sortie.png> <colonnes> <largeur d'une vue> <image:légende> ...
Chaque vue est réduite à la largeur donnée, sa légende écrite en haut à gauche."""
import sys
from PIL import Image, ImageDraw

out, columns, width = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
items = []
for arg in sys.argv[4:]:
    path, _, label = arg.partition(":")
    image = Image.open(path).convert("RGB")
    height = round(image.height * width / image.width)
    items.append((image.resize((width, height)), label))
height = max(image.height for image, _ in items)
rows = (len(items) + columns - 1) // columns
sheet = Image.new("RGB", (columns * width, rows * height), (20, 20, 20))
draw = ImageDraw.Draw(sheet)
for index, (image, label) in enumerate(items):
    x, y = (index % columns) * width, (index // columns) * height
    sheet.paste(image, (x, y))
    draw.rectangle((x, y, x + 8 + 7 * len(label), y + 16), fill=(0, 0, 0))
    draw.text((x + 4, y + 3), label, fill=(255, 255, 0))
sheet.save(out)
print(out, sheet.size)
