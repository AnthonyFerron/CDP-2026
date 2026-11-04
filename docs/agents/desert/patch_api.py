"""Chaque lancement de Godot vise une adresse locale morte : --api=http://127.0.0.1:9/api/v1 en argument utilisateur,
ignoré par les scripts de capture."""
from pathlib import Path

D = Path(__file__).parent
S = D.parent.parent
API = "--api=http://127.0.0.1:9/api/v1"

# Copie des captures libres, qui ignore les arguments « --... ».
cam = (S / "cam_shots.gd").read_text(encoding="utf-8")
cam = cam.replace("\tvar args := OS.get_cmdline_user_args()\n",
                  "\tvar args: Array = Array(OS.get_cmdline_user_args()).filter(func(a: String) -> bool: return not a.begins_with(\"--\"))\n", 1)
assert "filter(" in cam
(D / "cam_shots_desert.gd").write_text(cam, encoding="utf-8")

sheet = (D / "sheet_shots.gd").read_text(encoding="utf-8")
if "filter(" not in sheet:
    sheet = sheet.replace("\tvar args := OS.get_cmdline_user_args()\n",
                          "\tvar args: Array = Array(OS.get_cmdline_user_args()).filter(func(a: String) -> bool: return not a.begins_with(\"--\"))\n", 1)
    assert "filter(" in sheet
    (D / "sheet_shots.gd").write_text(sheet, encoding="utf-8")

shots = (D / "shots.ps1").read_text(encoding="utf-8")
shots = shots.replace('"$S/cam_shots.gd"', '"$S/agents/desert/cam_shots_desert.gd"')
shots = shots.replace('"agents/desert/$Out") + $Rest', f'"agents/desert/$Out", "{API}") + $Rest')
assert API in shots and "cam_shots_desert" in shots
(D / "shots.ps1").write_text(shots, encoding="utf-8")

sheets = (D / "sheets.ps1").read_text(encoding="utf-8")
if API not in sheets:
    sheets = sheets.replace('"--", $Out) + $Rest', f'"--", $Out, "{API}") + $Rest')
    assert API in sheets
    (D / "sheets.ps1").write_text(sheets, encoding="utf-8")

t = (D / "t.ps1").read_text(encoding="utf-8")
if API not in t:
    t = t.replace('if ($Rest) { $args2 += "--"; $args2 += $Rest }',
                  f'$args2 += "--"; if ($Rest) {{ $args2 += $Rest }}; if (-not ($Rest -contains "{API}")) {{ $args2 += "{API}" }}')
    assert API in t
    (D / "t.ps1").write_text(t, encoding="utf-8")
print("ok")
