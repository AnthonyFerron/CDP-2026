"""Hauteur maximale des sommets d'un .glb selon x et selon z. -- glb_slope.py <fichier>"""
import json, struct, sys
from collections import defaultdict
data = open(sys.argv[1], "rb").read()
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
for axis, label in ((0, "x"), (2, "z")):
    top = defaultdict(float)
    for p in points:
        top[round(p[axis], 2)] = max(top[round(p[axis], 2)], p[1])
    print(label, sorted((k, round(v, 3)) for k, v in top.items()))
