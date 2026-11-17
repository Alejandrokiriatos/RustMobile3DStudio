#!/usr/bin/env python3
"""Keep gameplay animation clips and repack GLB data for mobile packaging."""
import json
import pathlib
import struct
import sys

KEEP_ANIMATIONS = {
    "Idle", "Crouch idle", "Walk", "Run", "Walk backwards",
    "Strafe left", "Strafe right", "Jump", "Jump start",
    "Jump (in air)", "Jump land", "Fall", "Punch", "Hit reaction",
    "Death (fall forward)", "Death (fall backward)", "Get up (from back)",
    "Pick up (ground)", "Tread water", "Swim forward (front crawl)",
    "Swim breaststroke", "Climb ladder up", "Climb ladder down",
    "Vault over obstacle", "Rifle idle (low ready)",
    "Rifle fire (single)", "Rifle reload", "Rifle walk (aiming)", "Rifle run",
}
REQUIRED_ANIMATIONS = {"Idle", "Walk", "Run", "Jump"}


def optimize_glb(path: pathlib.Path):
    raw = path.read_bytes()
    if raw[:4] != b"glTF":
        raise ValueError(f"{path}: not a GLB file")
    version, total = struct.unpack_from("<II", raw, 4)
    if version != 2 or total != len(raw):
        raise ValueError(f"{path}: invalid GLB header")

    offset = 12
    document = None
    binary = b""
    while offset < len(raw):
        length, kind = struct.unpack_from("<I4s", raw, offset)
        chunk = raw[offset + 8:offset + 8 + length]
        if kind == b"JSON":
            document = json.loads(chunk.decode("utf-8").rstrip("\x00 "))
        elif kind == b"BIN\x00":
            binary = chunk
        offset += 8 + length
    if document is None or not binary:
        raise ValueError(f"{path}: missing JSON or binary chunk")

    original_animations = document.get("animations", [])
    kept = [clip for clip in original_animations if clip.get("name") in KEEP_ANIMATIONS]
    names = {clip.get("name") for clip in kept}
    if not REQUIRED_ANIMATIONS.issubset(names):
        raise ValueError(f"{path}: missing required clips: {REQUIRED_ANIMATIONS - names}")
    document["animations"] = kept

    used_accessors = set()
    for mesh in document.get("meshes", []):
        for primitive in mesh.get("primitives", []):
            used_accessors.update(primitive.get("attributes", {}).values())
            if "indices" in primitive:
                used_accessors.add(primitive["indices"])
            for target in primitive.get("targets", []):
                used_accessors.update(target.values())
    for skin in document.get("skins", []):
        if "inverseBindMatrices" in skin:
            used_accessors.add(skin["inverseBindMatrices"])
    for clip in kept:
        for sampler in clip.get("samplers", []):
            used_accessors.add(sampler["input"])
            used_accessors.add(sampler["output"])

    old_accessor_ids = sorted(used_accessors)
    accessor_map = {old: new for new, old in enumerate(old_accessor_ids)}
    accessors = [document["accessors"][old] for old in old_accessor_ids]
    used_views = set()
    for accessor in accessors:
        if "bufferView" in accessor:
            used_views.add(accessor["bufferView"])
        sparse = accessor.get("sparse")
        if sparse:
            used_views.add(sparse["indices"]["bufferView"])
            used_views.add(sparse["values"]["bufferView"])
    for image in document.get("images", []):
        if "bufferView" in image:
            used_views.add(image["bufferView"])

    view_map = {}
    new_views = []
    new_binary = bytearray()
    old_views = document["bufferViews"]
    for old in sorted(used_views, key=lambda index: old_views[index].get("byteOffset", 0)):
        view = dict(old_views[old])
        start = view.get("byteOffset", 0)
        length = view["byteLength"]
        while len(new_binary) % 4:
            new_binary.append(0)
        view["byteOffset"] = len(new_binary)
        view_map[old] = len(new_views)
        new_binary.extend(binary[start:start + length])
        new_views.append(view)

    for accessor in accessors:
        if "bufferView" in accessor:
            accessor["bufferView"] = view_map[accessor["bufferView"]]
        sparse = accessor.get("sparse")
        if sparse:
            sparse["indices"]["bufferView"] = view_map[sparse["indices"]["bufferView"]]
            sparse["values"]["bufferView"] = view_map[sparse["values"]["bufferView"]]

    document["accessors"] = accessors
    document["bufferViews"] = new_views
    document["buffers"][0]["byteLength"] = len(new_binary)
    for mesh in document.get("meshes", []):
        for primitive in mesh.get("primitives", []):
            primitive["attributes"] = {
                key: accessor_map[value]
                for key, value in primitive.get("attributes", {}).items()
            }
            if "indices" in primitive:
                primitive["indices"] = accessor_map[primitive["indices"]]
            for target in primitive.get("targets", []):
                for key, value in list(target.items()):
                    target[key] = accessor_map[value]
    for skin in document.get("skins", []):
        if "inverseBindMatrices" in skin:
            skin["inverseBindMatrices"] = accessor_map[skin["inverseBindMatrices"]]
    for clip in kept:
        for sampler in clip.get("samplers", []):
            sampler["input"] = accessor_map[sampler["input"]]
            sampler["output"] = accessor_map[sampler["output"]]
    for image in document.get("images", []):
        if "bufferView" in image:
            image["bufferView"] = view_map[image["bufferView"]]

    json_chunk = json.dumps(document, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    json_chunk += b" " * ((4 - len(json_chunk) % 4) % 4)
    new_binary.extend(b"\x00" * ((4 - len(new_binary) % 4) % 4))
    total_length = 12 + 8 + len(json_chunk) + 8 + len(new_binary)
    output = bytearray(struct.pack("<4sII", b"glTF", 2, total_length))
    output.extend(struct.pack("<I4s", len(json_chunk), b"JSON"))
    output.extend(json_chunk)
    output.extend(struct.pack("<I4s", len(new_binary), b"BIN\x00"))
    output.extend(new_binary)
    path.write_bytes(output)
    return len(raw), len(output), len(original_animations), len(kept), names


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "Models/Characters")
    files = sorted(root.glob("SKIN_*.glb"))
    if len(files) != 8:
        raise SystemExit(f"Expected 8 GLB files in {root}, found {len(files)}")

    results = {}
    for path in files:
        before, after, old_count, new_count, clips = optimize_glb(path)
        results[path.stem] = {"bytes": after, "animation_count": new_count}
        print(
            f"{path.name}: {before / 1048576:.2f} -> {after / 1048576:.2f} MB; "
            f"animations {old_count}->{new_count}"
        )

    manifest_path = root / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    for skin_id, metrics in results.items():
        manifest["skins"][skin_id]["bytes"] = metrics["bytes"]
        manifest["skins"][skin_id]["animation_count"] = metrics["animation_count"]
    manifest["optimized_for_mobile"] = True
    manifest["retained_animation_clips"] = sorted(KEEP_ANIMATIONS)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
