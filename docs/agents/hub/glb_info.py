"""Sommets d'un .glb : boîte, hauteurs distinctes, et coupes en x / z. -- glb_info.py <fichier>"""
import json, struct, sys
data = open(sys.argv[1], "rb").read()
length = struct.unpack_from("<I", data, 12)[0]
gltf = json.loads(data[20:20 + length])
binary_start = 20 + length + 8
for mesh in gltf["meshes"]:
    for primitive in mesh["primitives"]:
        accessor = gltf["accessors"][primitive["attributes"]["POSITION"]]
        view = gltf["bufferViews"][accessor["bufferView"]]
        offset = binary_start + view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
        stride = view.get("byteStride", 12)
        points = [struct.unpack_from("<3f", data, offset + i * stride) for i in range(accessor["count"])]
        print(mesh.get("name"), "min", accessor["min"], "max", accessor["max"], "count", len(points))
        print(" y:", sorted({round(p[1], 3) for p in points}))
        print(" x:", sorted({round(p[0], 3) for p in points}))
        print(" z:", sorted({round(p[2], 3) for p in points}))
for node in gltf["nodes"]:
    print("node", node.get("name"), node.get("translation"), node.get("rotation"), node.get("scale"))
