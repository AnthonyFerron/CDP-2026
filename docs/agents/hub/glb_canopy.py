"""Bas du feuillage d'un arbre .glb : plus petite hauteur des sommets éloignés du tronc. -- glb_canopy.py <fichiers...>"""
import json, struct, sys, math
for path in sys.argv[1:]:
    data = open(path, "rb").read()
    length = struct.unpack_from("<I", data, 12)[0]
    gltf = json.loads(data[20:20 + length])
    binary_start = 20 + length + 8
    points = []
    for mesh in gltf["meshes"]:
        for primitive in mesh["primitives"]:
            accessor = gltf["accessors"][primitive["attributes"]["POSITION"]]
            view = gltf["bufferViews"][accessor["bufferView"]]
            offset = binary_start + view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
            stride = view.get("byteStride", 12)
            points += [struct.unpack_from("<3f", data, offset + i * stride) for i in range(accessor["count"])]
    cx = sum(p[0] for p in points) / len(points); cz = sum(p[2] for p in points) / len(points)
    top = max(p[1] for p in points)
    far = [p[1] for p in points if math.hypot(p[0] - cx, p[2] - cz) > 0.28]
    print(path.split("/")[-1], "haut", round(top, 3), "bas du feuillage", round(min(far), 3) if far else None)
    low = min(far) if far else 0.0
    for limit in (1.65,):
        pass
    # Rayon du feuillage sous 0,45 de hauteur (à l'échelle 4 : 1,8 m, à hauteur des yeux).
    band = [math.hypot(p[0] - cx, p[2] - cz) for p in points if p[1] < 0.45]
    print("   rayon sous 0.45 :", round(max(band), 3) if band else None)
