#!/usr/bin/env python3
# UpdateProtobufSubtrees.py: vendor protobuf and abseil sources into this repo.
#
# USAGE
#   python3 scripts/UpdateProtobufSubtrees.py [--protobuf-tag TAG]
#
# WHAT IT DOES
#   1. Shallow-clones protobuf at the requested tag into a temp directory.
#   2. Reads protobuf_deps.bzl to find the required abseil commit and
#      shallow-clones abseil at that commit.
#   3. Replaces Sources/protobuf/protobuf and Sources/protobuf/abseil with
#      the subset of files listed in PROTOBUF_PATHS / ABSEIL_PATHS.
#   4. Updates Sources/protobuf/VERSIONS.json with the new versions.
#
# OPTIONS
#   --protobuf-tag TAG   Protobuf release tag to vendor (default: latest).
#   --allow-dirty        Skip the clean-worktree check.
#   --save-temps         Keep the temp checkout directory after completion
#                        (useful for debugging; the path is printed to stdout).
#   --github-output FILE Append GitHub Actions step outputs to FILE
#                        (pass "$GITHUB_OUTPUT" in CI).
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from urllib.request import urlopen
from typing import Optional

PROTOBUF_REMOTE = "https://github.com/protocolbuffers/protobuf.git"
ABSEIL_REMOTE = "https://github.com/abseil/abseil-cpp.git"
PROTOBUF_PREFIX = Path("Sources/protobuf/protobuf")
ABSEIL_PREFIX = Path("Sources/protobuf/abseil")
INCLUDE_PREFIX = Path("Sources/protobuf/include")
METADATA_FILE = Path("Sources/protobuf/VERSIONS.json")

# Paths copied from protocolbuffers/protobuf into the vendored subtree.
PROTOBUF_PATHS = [
    "LICENSE",
    "protobuf_deps.bzl",
    "conformance/**/*.proto",
    "go/**/*.proto",
    "java/core/src/main/resources/**/*.proto",
    "src/google/protobuf",
    "upb",
    "upb_generator",
    "third_party/utf8_range",
]

# Paths copied from abseil/abseil-cpp.
ABSEIL_PATHS = [
    "LICENSE",
    "PrivacyInfo.xcprivacy",
    "absl",
]


class CommandError(RuntimeError):
    pass


def run(cmd: list[str], *, cwd: Path | None = None, capture: bool = False, check: bool = True) -> str:
    proc = subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        text=True,
        capture_output=capture,
    )
    if check and proc.returncode != 0:
        stderr = proc.stderr.strip() if proc.stderr else ""
        stdout = proc.stdout.strip() if proc.stdout else ""
        msg = f"Command failed ({proc.returncode}): {' '.join(cmd)}"
        if stderr:
            msg += f"\n{stderr}"
        elif stdout:
            msg += f"\n{stdout}"
        raise CommandError(msg)
    return (proc.stdout or "") if capture else ""


def git(args: list[str], *, cwd: Path | None = None, capture: bool = False, check: bool = True) -> str:
    return run(["git", *args], cwd=cwd, capture=capture, check=check)


def ensure_clean_worktree(allow_dirty: bool) -> None:
    if allow_dirty:
        return
    status = git(["status", "--porcelain"], capture=True).strip()
    if status:
        raise CommandError("Working tree is dirty. Commit/stash first, or use --allow-dirty.")


def latest_protobuf_release_tag() -> str:
    with urlopen("https://api.github.com/repos/protocolbuffers/protobuf/releases/latest") as r:
        data = json.loads(r.read().decode("utf-8"))
    tag = data.get("tag_name")
    if not tag:
        raise CommandError("Failed to detect latest protobuf release tag from GitHub API")
    return tag


def checkout_shallow(remote: str, ref: str, out_dir: Path) -> None:
    git(["clone", "--depth", "1", remote, str(out_dir)])
    git(["fetch", "--depth", "1", "origin", ref], cwd=out_dir)
    git(["checkout", "--detach", "FETCH_HEAD"], cwd=out_dir)
    git(["fetch", "--depth", "1", "--tags", "origin"], cwd=out_dir, check=False)


def extract_abseil_ref_from_protobuf(protobuf_checkout: Path) -> str:
    deps = (protobuf_checkout / "protobuf_deps.bzl").read_text(encoding="utf-8")
    m = re.search(r'name\s*=\s*"abseil-cpp".*?commit\s*=\s*"([0-9a-f]+)"', deps, flags=re.S)
    return m.group(1) if m else ""


def copy_path(src_root: Path, dst_root: Path, rel: str) -> None:
    src = src_root / rel
    dst = dst_root / rel
    if not src.exists():
        raise CommandError(f"Required path missing in source checkout: {rel}")
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
        dst.mkdir(parents=True, exist_ok=True)
        for child in src.iterdir():
            target = dst / child.name
            if child.is_dir():
                shutil.copytree(child, target, dirs_exist_ok=True)
            else:
                shutil.copy2(child, target)
    else:
        shutil.copy2(src, dst)


def copy_glob(src_root: Path, dst_root: Path, pattern: str) -> None:
    matches = sorted(src_root.glob(pattern))
    if not matches:
        raise CommandError(f"Required glob matched no files in source checkout: {pattern}")
    for match in matches:
        rel = match.relative_to(src_root)
        if match.is_dir():
            copy_path(src_root, dst_root, str(rel))
        elif match.is_file():
            copy_path(src_root, dst_root, str(rel))


def vendor_update(prefix: Path, source_dir: Path, paths: list[str]) -> None:
    """Replace vendored directory with a fresh copy from source_dir."""
    if prefix.exists():
        shutil.rmtree(prefix)
    prefix.mkdir(parents=True, exist_ok=True)
    for rel in paths:
        copy_glob(source_dir, prefix, rel)
    git(["add", str(prefix)])


# Proto files bundled with protoc releases, mirroring wkt_protos_files and
# compiler_plugin_protos_files from protobuf's pkg/BUILD.bazel.
# Each entry is (source_path_in_checkout, dest_path_under_include).
INCLUDE_PROTOS: list[tuple[str, str]] = [
    # Well-known types
    ("src/google/protobuf/any.proto", "google/protobuf/any.proto"),
    ("src/google/protobuf/api.proto", "google/protobuf/api.proto"),
    ("src/google/protobuf/duration.proto", "google/protobuf/duration.proto"),
    ("src/google/protobuf/empty.proto", "google/protobuf/empty.proto"),
    ("src/google/protobuf/field_mask.proto", "google/protobuf/field_mask.proto"),
    ("src/google/protobuf/source_context.proto", "google/protobuf/source_context.proto"),
    ("src/google/protobuf/struct.proto", "google/protobuf/struct.proto"),
    ("src/google/protobuf/timestamp.proto", "google/protobuf/timestamp.proto"),
    ("src/google/protobuf/type.proto", "google/protobuf/type.proto"),
    ("src/google/protobuf/wrappers.proto", "google/protobuf/wrappers.proto"),
    # Descriptor
    ("src/google/protobuf/descriptor.proto", "google/protobuf/descriptor.proto"),
    # Edition feature protos
    ("src/google/protobuf/cpp_features.proto", "google/protobuf/cpp_features.proto"),
    ("go/google/protobuf/go_features.proto", "google/protobuf/go_features.proto"),
    ("java/core/src/main/resources/google/protobuf/java_features.proto", "google/protobuf/java_features.proto"),
    # Compiler plugin
    ("src/google/protobuf/compiler/plugin.proto", "google/protobuf/compiler/plugin.proto"),
]

# Proto files that may not exist in older protobuf versions.
INCLUDE_PROTOS_OPTIONAL: list[tuple[str, str]] = [
    ("csharp/google/protobuf/c_sharp_features.proto", "google/protobuf/c_sharp_features.proto"),
]


def build_include_dir(protobuf_checkout: Path) -> None:
    """Build the include/ directory with proto files that protoc ships."""
    if INCLUDE_PREFIX.exists():
        shutil.rmtree(INCLUDE_PREFIX)
    INCLUDE_PREFIX.mkdir(parents=True, exist_ok=True)
    for src_rel, dst_rel in INCLUDE_PROTOS:
        src = protobuf_checkout / src_rel
        dst = INCLUDE_PREFIX / dst_rel
        if not src.exists():
            raise CommandError(f"Expected proto file missing from checkout: {src_rel}")
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
    for src_rel, dst_rel in INCLUDE_PROTOS_OPTIONAL:
        src = protobuf_checkout / src_rel
        if not src.exists():
            continue
        dst = INCLUDE_PREFIX / dst_rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
    git(["add", str(INCLUDE_PREFIX)])


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_github_output(path: Optional[str], key: str, value: str) -> None:
    if path:
        with open(path, "a", encoding="utf-8") as f:
            f.write(f"{key}={value}\n")


@dataclass
class UpdateResult:
    protobuf_tag: str = ""
    protobuf_commit: str = ""
    abseil_commit: str = ""
    abseil_tag: str = ""


def main() -> int:
    parser = argparse.ArgumentParser(description="Update vendored protobuf/abseil snapshots.")
    parser.add_argument("--protobuf-tag", default="", help="Protobuf release tag. Defaults to latest release tag.")
    parser.add_argument("--save-temps", action="store_true", help="Preserve temporary workspace after completion.")
    parser.add_argument("--allow-dirty", action="store_true", help="Allow dirty working tree.")
    parser.add_argument("--github-output", default="", metavar="FILE", help="Append GitHub Actions outputs to FILE.")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    os.chdir(repo_root)

    if args.protobuf_tag:
        protobuf_tag = args.protobuf_tag
    else:
        current_tag = ""
        if METADATA_FILE.exists():
            data = json.loads(METADATA_FILE.read_text(encoding="utf-8"))
            current_tag = data.get("protobuf", {}).get("tag", "")
        protobuf_tag = latest_protobuf_release_tag()
        print(f"Latest: {protobuf_tag}  Current: {current_tag or '<none>'}")
        if protobuf_tag == current_tag:
            print("No update needed")
            write_github_output(args.github_output, "updated", "false")
            return 0
        print(f"Update needed: {current_tag or '<none>'} -> {protobuf_tag}")

    ensure_clean_worktree(args.allow_dirty)

    with tempfile.TemporaryDirectory(prefix="swift-protobuf-vendor-", delete=not args.save_temps) as tmp:
        tmp_dir = Path(tmp)
        if args.save_temps:
            print(f"Temp dir: {tmp_dir}")

        result = UpdateResult(protobuf_tag=protobuf_tag)

        protobuf_checkout = tmp_dir / "protobuf-checkout"
        checkout_shallow(PROTOBUF_REMOTE, protobuf_tag, protobuf_checkout)
        result.protobuf_commit = git(["rev-parse", "HEAD"], cwd=protobuf_checkout, capture=True).strip()

        abseil_ref = extract_abseil_ref_from_protobuf(protobuf_checkout)
        if not abseil_ref:
            raise CommandError("Unable to determine abseil commit from protobuf_deps.bzl")

        abseil_checkout = tmp_dir / "abseil-checkout"
        checkout_shallow(ABSEIL_REMOTE, abseil_ref, abseil_checkout)
        result.abseil_commit = abseil_ref
        result.abseil_tag = git(["describe", "--tags", "--abbrev=0"], cwd=abseil_checkout, capture=True, check=False).strip()

        vendor_update(PROTOBUF_PREFIX, protobuf_checkout, PROTOBUF_PATHS)
        vendor_update(ABSEIL_PREFIX, abseil_checkout, ABSEIL_PATHS)
        build_include_dir(protobuf_checkout)

        write_json(METADATA_FILE, {
            "protobuf": {"commit": result.protobuf_commit, "tag": result.protobuf_tag},
            "abseil": {"commit": result.abseil_commit, "tag": result.abseil_tag},
        })

        git(["add", str(METADATA_FILE)])

        write_github_output(args.github_output, "updated", "true")
        write_github_output(args.github_output, "protobuf_tag", result.protobuf_tag)
        write_github_output(args.github_output, "abseil_tag", result.abseil_tag)
        write_github_output(args.github_output, "abseil_commit", result.abseil_commit)

        print("Updated vendored dependencies")
        print(f"  protobuf: {result.protobuf_tag} ({result.protobuf_commit})")
        extra = f" tag:{result.abseil_tag}" if result.abseil_tag else ""
        print(f"  abseil:   {result.abseil_commit}{extra}")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except CommandError as e:
        print(str(e), file=sys.stderr)
        raise SystemExit(1)
