# Planche avant | après d'un lieu : compare.py <lieu> [échelle]
import sys, os
from PIL import Image, ImageDraw
base = os.path.expanduser("~/cdp-dev/.claude/captures/perf-ombres")
lieu = sys.argv[1]
scale = float(sys.argv[2]) if len(sys.argv) > 2 else 0.5
views = sorted(os.listdir(f"{base}/avant/shots/{lieu}"))
rows = []
for v in views:
    pair = []
    for tag in ("avant", sys.argv[3] if len(sys.argv) > 3 else "apres"):
        path = f"{base}/{tag}/shots/{lieu}/{v}"
        if not os.path.exists(path):
            continue
        im = Image.open(path).convert("RGB")
        im = im.resize((int(im.width * scale), int(im.height * scale)), Image.LANCZOS)
        d = ImageDraw.Draw(im)
        d.rectangle((0, 0, 200, 14), fill=(0, 0, 0))
        d.text((3, 1), f"{tag} {lieu} {v[:-4]}", fill=(255, 255, 0))
        pair.append(im)
    if len(pair) == 2:
        rows.append(pair)
w, h = rows[0][0].size
sheet = Image.new("RGB", (w * 2, h * len(rows)))
for i, (a, b) in enumerate(rows):
    sheet.paste(a, (0, i * h)); sheet.paste(b, (w, i * h))
os.makedirs(f"{base}/planches", exist_ok=True)
sheet.save(f"{base}/planches/{lieu}.png")
# usage : compare.py <lieu> [échelle] [dossier après]
print(f"{base}/planches/{lieu}.png", len(rows), "vues")
