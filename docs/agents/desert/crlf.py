"""Compte les fins de ligne CRLF des fichiers du désert ; avec --fix, les remet en LF."""
import sys
from pathlib import Path

F = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend")
files = [F / "tools/build_desert.py", F / "scripts/hints.gd"] + sorted((F / "scenes/levels/desert").glob("*.*"))
for f in files:
    data = f.read_bytes()
    count = data.count(b"\r\n")
    if count:
        print(count, f.name)
        if "--fix" in sys.argv:
            f.write_bytes(data.replace(b"\r\n", b"\n"))
print("fin")
