"""Résout le conflit de MODEL_BOXES : garde les entrées de dev et MEDIEVAL, puis les ajouts de la Plaine."""
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
match = re.search(r"<<<<<<< HEAD\n(.*?)=======\n(.*?)>>>>>>> dev\n", text, re.S)
mine, theirs = match.group(1), match.group(2)
dev_entries, rest = theirs.split("}\n", 1)
dev_keys = set(re.findall(r'^\s+"([^"]+)":', dev_entries, re.M))
kept = "".join(line + "\n" for line in mine.splitlines()
               if not any(f'"{key}":' in line for key in dev_keys))
merged = dev_entries + kept + "}\n" + rest
path.write_text(text[:match.start()] + merged + text[match.end():], encoding="utf-8", newline="\n")
print("entrées de dev :", sorted(dev_keys))
