"""Applique des remplacements exacts à un fichier : python patch.py <fichier> <remplacements.py>
Le fichier de remplacements définit REPLACEMENTS = [(ancien, nouveau), ...]."""
import runpy
import sys

path = sys.argv[1]
replacements = runpy.run_path(sys.argv[2])["REPLACEMENTS"]
text = open(path, encoding="utf-8").read()
for old, new in replacements:
    count = text.count(old)
    if count != 1:
        sys.exit(f"{count} occurrence(s) de : {old[:80]!r}")
    text = text.replace(old, new)
open(path, "w", encoding="utf-8", newline="\n").write(text)
print(f"{len(replacements)} remplacement(s) dans {path}")
