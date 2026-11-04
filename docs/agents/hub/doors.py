"""Portes des nouveaux bâtiments du hub : point devant la porte et point à l'intérieur, en JSON, comme hub_houses.json.
Usage : python doors.py <dossier tools> <sortie.json>"""
import json
import sys

sys.path.insert(0, sys.argv[1])
import build_hub as bh  # noqa: E402

doors = []
for name, house, stage, kind in bh.QUARTERS:
    frame = bh.HouseFrame(house)
    outside = frame.at(frame.door_u, frame.half_v + 3.0)
    inside = frame.at(frame.door_u, frame.half_v - 1.6)
    doors.append({"name": name, "door": [outside[0], outside[2]], "inside": [inside[0], inside[2]]})
json.dump(doors, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False, indent=1)
for d in doors:
    print(d)
