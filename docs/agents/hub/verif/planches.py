"""Planches de vues : planches.py <dossier> <préfixe> <colonnes> [sortie] — les PNG du dossier dont le nom commence par
le préfixe (hors planches), dans l'ordre du fichier de vues s'il est donné par VUES=..., en planches de colonnes x
colonnes (1280 x 720), légendées. Écrit <dossier>/p_<préfixe>_NN.png."""
import os
import sys
from PIL import Image, ImageDraw

folder, prefix, columns = sys.argv[1], sys.argv[2], int(sys.argv[3])
order = os.environ.get("VUES")
if order:
    names = [line.split()[0] for line in open(order) if line.strip() and line.split()[0].startswith(prefix)]
    names = [n for n in names if os.path.exists(os.path.join(folder, n + ".png"))]
else:
    names = sorted(f[:-4] for f in os.listdir(folder) if f.startswith(prefix) and f.endswith(".png"))
w, h = 1280 // columns, 720 // columns
per = columns * columns
for start in range(0, len(names), per):
    sheet = Image.new("RGB", (1280, 720), (20, 20, 20))
    draw = ImageDraw.Draw(sheet)
    for slot, name in enumerate(names[start:start + per]):
        image = Image.open(os.path.join(folder, name + ".png")).convert("RGB").resize((w, h))
        x, y = (slot % columns) * w, (slot // columns) * h
        sheet.paste(image, (x, y))
        label = name[len(prefix):].strip("_") or name
        draw.rectangle((x, y, x + 6 + 6 * len(label), y + 12), fill=(0, 0, 0))
        draw.text((x + 3, y + 1), label, fill=(255, 255, 0))
    out = os.path.join(folder, f"p_{prefix}_{start // per:02d}.png")
    sheet.save(out)
print(prefix, len(names), "vues,", (len(names) + per - 1) // per, "planches")
