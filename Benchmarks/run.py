#!/usr/bin/env python3
#
# Benchmarks/run.py - build and run the benchmarks against one or more checkouts.
#
# Copyright (c) 2014 - 2026 Apple Inc. and the project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See LICENSE.txt for license information:
# https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
#
# -----------------------------------------------------------------------------
#
# Each baseline is a swift-protobuf checkout. The runtime *and* the protoc-gen-swift
# that generates the message types both come from it. The table-driven branch emits a
# different shape of generated code than main. The measurement therefore covers both
# runtime and codegen.
#
# The benchmark sources are deliberately NOT an SwiftPM package. A package here would
# need a path dependency on its own containing checkout, which SwiftPM treats as a
# nested package. A direct link of the built module also keeps the measured checkout a
# pure `-I`/`-L` input. An edited working tree then needs no manifest changes.
#
# Usage:
#   ./run.py                              # compare main against this worktree
#   ./run.py <label>=<checkout> ...       # compare explicit baselines
#   SP_GEN_OPTS=ExperimentalHiddenNames=All ./run.py ...
#
# -----------------------------------------------------------------------------

import glob
import os
import shutil
import subprocess
import sys

import report

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(HERE)
WORK_DIR = os.path.join(HERE, "_build")
RESULTS_DIR = os.path.join(HERE, "_results")

# Extra `--swift_out` generator options, e.g. ExperimentalHiddenNames=All. These apply
# to every baseline. A baseline whose generator does not know the option fails loudly
# rather than produce un-stripped code.
GEN_OPTS = os.environ.get("SP_GEN_OPTS", "")


def run(argv, **kwargs):
    """Run a command. Stop the script on a non-zero exit, like `set -e`."""
    return subprocess.run(argv, check=True, **kwargs)


def build_and_run(label, checkout, protoc):
    """Build the runtime and the plugin from `checkout`, regenerate the message types
    with that checkout's plugin, link the benchmark, and run it."""
    out = os.path.join(WORK_DIR, label)

    if not os.path.isfile(os.path.join(checkout, "Package.swift")):
        print(f"error: {checkout} is not a swift-protobuf checkout", file=sys.stderr)
        return False

    print(f"==> [{label}] building runtime + protoc-gen-swift from {checkout}")
    # --disable-sandbox: manifest compilation runs swiftc under sandbox-exec. That
    # fails with "sandbox_apply: Operation not permitted" when the build itself already
    # runs inside a sandbox.
    swiftpm = ["swift", "build", "-c", "release", "--disable-sandbox"]
    run(swiftpm + ["--target", "SwiftProtobuf"], cwd=checkout, stdout=subprocess.DEVNULL)
    run(swiftpm + ["--product", "protoc-gen-swift"], cwd=checkout, stdout=subprocess.DEVNULL)
    bin_path = run(
        swiftpm + ["--show-bin-path"], cwd=checkout, capture_output=True, text=True
    ).stdout.strip()

    print(f"==> [{label}] generating message types")
    generated = os.path.join(out, "Generated")
    shutil.rmtree(generated, ignore_errors=True)
    os.makedirs(generated)
    swift_out = f"{GEN_OPTS}:{generated}" if GEN_OPTS else generated
    for proto in sorted(glob.glob(os.path.join(HERE, "protos", "*.proto"))):
        run([
            protoc,
            f"--plugin=protoc-gen-swift={os.path.join(bin_path, 'protoc-gen-swift')}",
            f"--swift_out={swift_out}",
            "-I", os.path.join(HERE, "protos"),
            proto,
        ])

    print(f"==> [{label}] linking benchmark")
    # -dead_strip so the size axis reflects what an app would ship. That is only the
    # runtime the generated code reaches.
    bench = os.path.join(out, "bench")
    run([
        "xcrun", "swiftc", "-O", "-wmo",
        "-I", bin_path, "-I", os.path.join(bin_path, "Modules"),
        "-Xlinker", "-dead_strip",
        "-o", bench,
        *sorted(glob.glob(os.path.join(HERE, "Sources", "*.swift"))),
        *sorted(glob.glob(os.path.join(generated, "*.swift"))),
        os.path.join(bin_path, "SwiftProtobuf.o"),
    ])

    print(f"==> [{label}] running")
    kv_path = os.path.join(RESULTS_DIR, f"{label}.kv")
    env = dict(os.environ, SP_BASELINE=label)
    # Tee the benchmark output: show it live and keep a copy for the KV file.
    with open(kv_path, "w") as handle:
        proc = subprocess.Popen(
            [bench], env=env, stdout=subprocess.PIPE, text=True
        )
        for line in proc.stdout:
            sys.stdout.write(line)
            handle.write(line)
        if proc.wait() != 0:
            raise subprocess.CalledProcessError(proc.returncode, bench)

    # Code-size axis. The stripped benchmark binary is the same program for every
    # baseline. Its size differences therefore come from the runtime and generated code.
    bench_stripped = os.path.join(out, "bench_stripped")
    shutil.copyfile(bench, bench_stripped)
    shutil.copymode(bench, bench_stripped)
    run(["strip", "-u", "-r", bench_stripped])
    size_output = run(["size", bench], capture_output=True, text=True).stdout
    text_size = size_output.splitlines()[1].split()[0]
    generated_bytes = sum(
        os.path.getsize(f) for f in glob.glob(os.path.join(generated, "*.swift"))
    )
    metric_lines = [
        f"KV baseline={label} metric=binary_bytes value={os.path.getsize(bench)}",
        f"KV baseline={label} metric=binary_bytes_stripped value={os.path.getsize(bench_stripped)}",
        f"KV baseline={label} metric=text_bytes value={text_size}",
        f"KV baseline={label} metric=generated_source_bytes value={generated_bytes}",
    ]
    for line in metric_lines:
        print(line)
    with open(kv_path, "a") as handle:
        handle.write("".join(line + "\n" for line in metric_lines))
    return True


def main():
    protoc = os.environ.get("PROTOC") or shutil.which("protoc")
    if not protoc:
        print("error: protoc not found; set PROTOC=/path/to/protoc", file=sys.stderr)
        return 1

    # Default comparison: upstream main versus the branch this worktree is on.
    if len(sys.argv) == 1:
        baselines = [
            f"main={os.path.join(REPO_ROOT, '..', 'swift-protobuf')}",
            f"table-driven={REPO_ROOT}",
        ]
    else:
        baselines = sys.argv[1:]

    os.makedirs(WORK_DIR, exist_ok=True)
    os.makedirs(RESULTS_DIR, exist_ok=True)

    kv_paths = []
    for baseline in baselines:
        label, _, checkout = baseline.partition("=")
        print()
        print("================================================================")
        print(f"=== {label}")
        print("================================================================")
        if not build_and_run(label, checkout, protoc):
            return 1
        kv_paths.append(os.path.join(RESULTS_DIR, f"{label}.kv"))

    # Collate only the baselines this run produced, in the order named. `_results/` is
    # not cleaned between runs, so a glob would fold in stale files from earlier runs.
    print()
    print("==> collating")
    timings, metrics, order = report.parse(kv_paths)
    report.render(timings, metrics, order)
    return 0


if __name__ == "__main__":
    sys.exit(main())
