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
#   4. Replaces Sources/protobuf/include with the include/ directory from the
#      release's prebuilt protoc archive.
#   5. Updates Sources/protobuf/VERSIONS.json with the new versions.
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
import zipfile
from dataclasses import dataclass
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import urlopen
from typing import Any, Optional

PROTOBUF_REMOTE = "https://github.com/protocolbuffers/protobuf.git"
PROTOBUF_RELEASES_API = "https://api.github.com/repos/protocolbuffers/protobuf/releases"
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

# Files copied from protocolbuffers/protobuf that are deliberately not built.
PROTOBUF_PRUNE = [
    # SwiftProtobuf provides its own entry point which includes the include
    # path to WKTs in the source tree.
    "src/google/protobuf/compiler/main_no_generators.cc",
    # SwiftProtobuf's protoc target only supports external protoc-* plugins.
    # It does not compile or register upstream's built-in language generators,
    # so keep the vendored checkout smaller by pruning those implementation
    # trees after the protobuf snapshot is copied.
    "src/google/protobuf/compiler/cpp",
    "src/google/protobuf/compiler/csharp",
    "src/google/protobuf/compiler/java",
    "src/google/protobuf/compiler/kotlin",
    "src/google/protobuf/compiler/objectivec",
    "src/google/protobuf/compiler/php",
    "src/google/protobuf/compiler/python",
    "src/google/protobuf/compiler/ruby",
    "src/google/protobuf/compiler/rust",
    # Upstream C++ tests and fixtures are not built by SwiftPM here. The Swift
    # package has its own tests under Tests/, Protos/, Reference/, CompileTests/,
    # and FuzzTesting/.
    "src/google/protobuf/testdata",
    "src/google/protobuf/testing",
    "src/google/protobuf/util/python/testdata",
]

# Paths copied from abseil/abseil-cpp.
ABSEIL_PATHS = [
    "LICENSE",
    "PrivacyInfo.xcprivacy",
    "absl",
]

ABSEIL_PRUNE = [
    # Timezone fixture files support upstream cctz tests only. The package
    # builds the cctz implementation, but does not run or ship those fixtures.
    "absl/time/internal/cctz/testdata",
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


def fetch_protobuf_release(tag: str = "") -> dict[str, Any]:
    url = f"{PROTOBUF_RELEASES_API}/tags/{tag}" if tag else f"{PROTOBUF_RELEASES_API}/latest"
    try:
        with urlopen(url) as r:
            data = json.loads(r.read().decode("utf-8"))
    except HTTPError as e:
        target = f"tag '{tag}'" if tag else "latest release"
        raise CommandError(f"Failed to fetch protobuf {target} from GitHub API ({url}): {e}") from e
    if not data.get("tag_name"):
        raise CommandError(f"Failed to detect protobuf release tag from GitHub API ({url})")
    return data


def find_protoc_zip_asset_url(release_data: dict[str, Any]) -> str:
    assets = release_data.get("assets") or []
    protoc_zips = [
        asset for asset in assets
        if asset.get("name", "").startswith("protoc-")
        and asset.get("name", "").endswith(".zip")
        and asset.get("browser_download_url")
    ]
    if not protoc_zips:
        tag = release_data.get("tag_name", "<unknown>")
        raise CommandError(f"No protoc-*.zip release asset found for protobuf {tag}")
    # Any platform's protoc archive bundles the same include/ directory; prefer
    # linux-x86_64 for consistency if present, otherwise use the first match.
    for asset in protoc_zips:
        if asset["name"].endswith("-linux-x86_64.zip"):
            return asset["browser_download_url"]
    return protoc_zips[0]["browser_download_url"]


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


def prune_vendored(prefix: Path, paths: list[str]) -> None:
    """Remove files from the vendored tree."""
    for rel in paths:
        target = prefix / rel
        if not target.exists():
            raise CommandError(f"Prune target missing from vendored tree: {rel}")
        if target.is_dir():
            git(["rm", "-r", "-f", str(target)])
        else:
            git(["rm", "-f", str(target)])


def build_include_dir(release_data: dict[str, Any], tmp_dir: Path) -> None:
    """Populate the include/ directory from the release's prebuilt protoc zip archive."""
    asset_url = find_protoc_zip_asset_url(release_data)
    zip_path = tmp_dir / "protoc-release.zip"
    with urlopen(asset_url) as r, open(zip_path, "wb") as out:
        shutil.copyfileobj(r, out)

    if INCLUDE_PREFIX.exists():
        shutil.rmtree(INCLUDE_PREFIX)
    INCLUDE_PREFIX.mkdir(parents=True, exist_ok=True)

    extracted_files = 0
    with zipfile.ZipFile(zip_path) as zf:
        for member in zf.infolist():
            if member.is_dir():
                continue
            member_path = Path(member.filename)
            if not member_path.parts or member_path.parts[0] != "include":
                continue
            rel_path = member_path.relative_to("include")
            if ".." in rel_path.parts:
                raise CommandError(f"Unexpected path in protoc archive: {member.filename}")
            dst = INCLUDE_PREFIX / rel_path
            dst.parent.mkdir(parents=True, exist_ok=True)
            with zf.open(member) as src_file, open(dst, "wb") as dst_file:
                shutil.copyfileobj(src_file, dst_file)
            extracted_files += 1

    if extracted_files == 0:
        raise CommandError(f"No files found under include/ in {asset_url}")

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
        release_data = fetch_protobuf_release(args.protobuf_tag)
        protobuf_tag = release_data["tag_name"]
    else:
        current_tag = ""
        if METADATA_FILE.exists():
            data = json.loads(METADATA_FILE.read_text(encoding="utf-8"))
            current_tag = data.get("protobuf", {}).get("tag", "")
        release_data = fetch_protobuf_release()
        protobuf_tag = release_data["tag_name"]
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
        prune_vendored(PROTOBUF_PREFIX, PROTOBUF_PRUNE)
        vendor_update(ABSEIL_PREFIX, abseil_checkout, ABSEIL_PATHS)
        prune_vendored(ABSEIL_PREFIX, ABSEIL_PRUNE)
        build_include_dir(release_data, tmp_dir)

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
