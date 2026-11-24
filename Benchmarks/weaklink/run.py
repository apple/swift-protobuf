#!/usr/bin/env python3
#
# Benchmarks/weaklink/run.py - measure the size effect of @_weakLinked import.
#
# Copyright (c) 2014 - 2026 Apple Inc. and the project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See LICENSE.txt for license information:
# https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
#
# -----------------------------------------------------------------------------
#
# Builds the same two-module program four ways -- {static, dynamic} x {strong, weak}
# -- and reports the size of each. `Common` holds 40 generated message types; the
# program references exactly one. Anything the linker keeps beyond that one type is
# waste that weak-linking might be able to shed.
#
# SwiftProtobuf itself is built once as a shared library and linked dynamically by
# everything, so the runtime is a constant that sits outside every number reported
# here. Without that, each image statically absorbs its own ~1 MB copy of the runtime
# and swamps the generated-code differences this is trying to measure.
#
# The weak variant is produced by rewriting the `import Common` line that
# protoc-gen-swift emits into `@_weakLinked import Common`. Doing it downstream keeps
# the experiment honest about what a generator option would have to emit.
#
# Usage:
#   ./run.py [<checkout>]                # defaults to the containing checkout
#   SP_GEN_OPTS=ExperimentalHiddenNames=All ./run.py
#
# -----------------------------------------------------------------------------

import glob
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "_build")
GEN_OPTS = os.environ.get("SP_GEN_OPTS", "")

# Touches exactly one of Common's forty message types.
MAIN_SWIFT = """\
import Common
import SwiftProtobuf

var envelope = App_Envelope()
envelope.id = 7
envelope.payload.f0 = 42
let bytes: [UInt8] = try envelope.serializedBytes()
let decoded = try App_Envelope(serializedBytes: bytes)
print(decoded.payload.f0)
"""


def run(argv, **kwargs):
    """Run a command. Stop the script on a non-zero exit, like `set -e`."""
    return subprocess.run(argv, check=True, **kwargs)


def read(path):
    with open(path) as handle:
        return handle.read()


def write(path, text):
    with open(path, "w") as handle:
        handle.write(text)


def weaklink(path):
    """Rewrite `import Common` into `@_weakLinked import Common`, in place."""
    write(path, read(path).replace("import Common\n", "@_weakLinked import Common\n"))


def text_size(path):
    """__text size of a Mach-O: the code the image actually carries."""
    output = run(["size", path], capture_output=True, text=True).stdout
    return int(output.splitlines()[1].split()[0])


def report(handle, variant, metric, value):
    line = f"KV variant={variant} metric={metric} value={value}"
    print(line)
    handle.write(line + "\n")


def build_variant(handle, linkage, binding, runtime):
    tag = f"{linkage}-{binding}"
    directory = os.path.join(OUT, tag)
    os.makedirs(directory, exist_ok=True)

    app_pb = os.path.join(directory, "app.pb.swift")
    main = os.path.join(directory, "main.swift")
    shutil.copyfile(os.path.join(OUT, "gen", "app.pb.swift"), app_pb)
    shutil.copyfile(os.path.join(OUT, "main.swift"), main)
    if binding == "weak":
        # The change under test. It has to be applied to *every* file in the module
        # that imports Common: Swift rejects a module imported @_weakLinked in one file
        # and normally in another ("inconsistently imported with @_weakLinked"), so
        # hand-written code importing a proto module must be annotated too, not just
        # the generated file.
        weaklink(app_pb)
        weaklink(main)

    # -parse-as-library: without it a lone source file becomes a main module and emits
    # its own _main, which collides with the app's at link time.
    if linkage == "dynamic":
        common_out = ["-emit-library", "-o", os.path.join(directory, "libCommon.dylib")]
    else:
        common_out = ["-c", "-o", os.path.join(directory, "Common.o")]
    run([
        "xcrun", "swiftc", "-O", "-wmo", "-parse-as-library",
        "-module-name", "Common", "-emit-module",
        "-emit-module-path", os.path.join(directory, "Common.swiftmodule"),
        *common_out, *runtime,
        os.path.join(OUT, "gen", "common.pb.swift"),
    ])

    if linkage == "dynamic":
        link_inputs = ["-L", directory, "-lCommon", "-Xlinker", "-rpath", "-Xlinker", directory]
    else:
        link_inputs = [os.path.join(directory, "Common.o")]

    app = os.path.join(directory, "app")
    run([
        "xcrun", "swiftc", "-O", "-wmo", "-o", app,
        "-I", directory, "-Xlinker", "-dead_strip",
        app_pb, main, *runtime, *link_inputs,
    ])

    # A size win from a binary that cannot run is not a size win.
    report(handle, tag, "runs", 1 if runs(app) else 0)

    report(handle, tag, "app_text_bytes", text_size(app))
    if linkage == "dynamic":
        dylib = os.path.join(directory, "libCommon.dylib")
        report(handle, tag, "common_dylib_text_bytes", text_size(dylib))
        report(handle, tag, "total_text_bytes", text_size(app) + text_size(dylib))
    else:
        report(handle, tag, "total_text_bytes", text_size(app))

    # Distinct Shared types the app image still names. Meaningful only for the dynamic
    # variants: a static -wmo link internalizes these symbols, so a zero there says
    # nothing about whether the code survived.
    report(handle, tag, "common_types_named_in_app", common_types_named(app))


def runs(path):
    """True if the binary exits zero. A crash or a signal is a False."""
    return subprocess.run(
        [path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    ).returncode == 0


def common_types_named(app):
    output = subprocess.run(
        ["nm", "-a", app], capture_output=True, text=True
    ).stdout
    names = set()
    for line in output.splitlines():
        start = line.find("Common_Shared")
        if start != -1:
            token = line[start:start + len("Common_Shared") + 2]
            if token[-2:].isdigit():
                names.add(token)
    return len(names)


def omitted(handle, runtime):
    """The configuration that could actually pay off. Weak-linking changes symbol
    binding, not stripping, so on its own it cannot shrink anything -- what it buys is
    the ability to ship *without* the dependency at all. Here the app never touches the
    payload field, so Common is reachable only through the generated schema. The app is
    linked -weak-lCommon and then run with libCommon.dylib moved aside. If that works,
    an app can drop entire proto modules it only references structurally, and the saving
    is the whole dylib rather than a few stripped functions."""
    directory = os.path.join(OUT, "dynamic-weak-omitted")
    os.makedirs(directory, exist_ok=True)

    main = os.path.join(directory, "main.swift")
    text = read(os.path.join(OUT, "main.swift"))
    text = text.replace("envelope.payload.f0 = 42\n", "")
    text = text.replace("print(decoded.payload.f0)", "print(decoded.id)")
    write(main, text)
    app_pb = os.path.join(directory, "app.pb.swift")
    shutil.copyfile(os.path.join(OUT, "gen", "app.pb.swift"), app_pb)
    weaklink(app_pb)
    weaklink(main)

    dylib = os.path.join(directory, "libCommon.dylib")
    run([
        "xcrun", "swiftc", "-O", "-wmo", "-parse-as-library",
        "-module-name", "Common", "-emit-module",
        "-emit-module-path", os.path.join(directory, "Common.swiftmodule"),
        "-emit-library", "-o", dylib, *runtime,
        os.path.join(OUT, "gen", "common.pb.swift"),
    ])

    app = os.path.join(directory, "app")
    # -weak-lCommon: weakly load the whole library, so dyld tolerates its absence.
    run([
        "xcrun", "swiftc", "-O", "-wmo", "-o", app,
        "-I", directory, "-Xlinker", "-dead_strip",
        app_pb, main, *runtime,
        "-L", directory, "-Xlinker", "-weak-lCommon", "-Xlinker", "-rpath", "-Xlinker", directory,
    ])

    report(handle, "dynamic-weak-omitted", "app_text_bytes", text_size(app))
    report(handle, "dynamic-weak-omitted", "total_text_bytes", text_size(app))

    # The other half of the experiment: an app that *does* touch the omitted type.
    # Built into its own directory because top-level code is only allowed in a file
    # named main.swift.
    touching = os.path.join(directory, "touching")
    os.makedirs(touching, exist_ok=True)
    touching_main = os.path.join(touching, "main.swift")
    touching_pb = os.path.join(touching, "app.pb.swift")
    shutil.copyfile(os.path.join(OUT, "main.swift"), touching_main)
    shutil.copyfile(os.path.join(OUT, "gen", "app.pb.swift"), touching_pb)
    weaklink(touching_pb)
    weaklink(touching_main)
    touching_app = os.path.join(touching, "app")
    run([
        "xcrun", "swiftc", "-O", "-wmo", "-o", touching_app,
        "-I", directory, "-Xlinker", "-dead_strip",
        touching_pb, touching_main, *runtime,
        "-L", directory, "-Xlinker", "-weak-lCommon", "-Xlinker", "-rpath", "-Xlinker", directory,
    ])

    # Move the dependency aside. The dylib's install name is this exact path, so this
    # genuinely makes it unavailable -- a copy left anywhere else would still be found
    # and would quietly invalidate both checks below.
    absent = dylib + ".absent"
    os.rename(dylib, absent)
    try:
        # The claim: an app that only references the type structurally still runs.
        report(handle, "dynamic-weak-omitted", "runs", 1 if runs(app) else 0)
        # The cost: an app that actually reaches the field does not fail gracefully, it
        # takes a signal. Recorded rather than asserted so the number is visible next to
        # the size win it pays for.
        report(handle, "dynamic-weak-omitted", "touching_omitted_type_runs",
               1 if runs(touching_app) else 0)
    finally:
        os.rename(absent, dylib)


def collate(path):
    rows, variants, metrics = {}, [], []
    for line in read(path).splitlines():
        if not line.startswith("KV "):
            continue
        kv = dict(part.split("=", 1) for part in line.split()[1:])
        variant, metric = kv["variant"], kv["metric"]
        if variant not in variants:
            variants.append(variant)
        if metric not in metrics:
            metrics.append(metric)
        rows[(variant, metric)] = int(kv["value"])

    width = max(len(v) for v in variants) + 4
    header = f"{'metric':<28}" + "".join(f"{v:>{width}}" for v in variants)
    print(header)
    print("-" * len(header))
    for metric in metrics:
        line = f"{metric:<28}"
        for variant in variants:
            value = rows.get((variant, metric))
            line += f"{value:>{width},}" if value is not None else f"{'-':>{width}}"
        print(line)

    print()
    for linkage in ("static", "dynamic"):
        strong = rows.get((f"{linkage}-strong", "total_text_bytes"))
        weak = rows.get((f"{linkage}-weak", "total_text_bytes"))
        if strong and weak:
            print(f"{linkage}: weak-linking changes total __text by {weak - strong:+,} bytes "
                  f"({(weak / strong - 1) * 100:+.1f}%)")


def main():
    checkout = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(HERE))
    protoc = os.environ.get("PROTOC") or shutil.which("protoc")

    run([sys.executable, os.path.join(HERE, "generate.py")])

    print(f"==> building plugin from {checkout}")
    swiftpm = ["swift", "build", "-c", "release", "--disable-sandbox"]
    run(swiftpm + ["--product", "protoc-gen-swift"], cwd=checkout, stdout=subprocess.DEVNULL)
    bin_path = run(
        swiftpm + ["--show-bin-path"], cwd=checkout, capture_output=True, text=True
    ).stdout.strip()

    shutil.rmtree(OUT, ignore_errors=True)
    os.makedirs(os.path.join(OUT, "gen"))
    os.makedirs(os.path.join(OUT, "runtime"))

    print("==> building SwiftProtobuf as a shared library")
    # -package-name: the runtime uses `package` access internally, which a raw swiftc
    # invocation outside SwiftPM does not otherwise grant.
    runtime_dir = os.path.join(OUT, "runtime")
    run([
        "xcrun", "swiftc", "-emit-library", "-emit-module", "-O", "-wmo", "-parse-as-library",
        "-package-name", "SwiftProtobuf", "-module-name", "SwiftProtobuf",
        "-emit-module-path", os.path.join(runtime_dir, "SwiftProtobuf.swiftmodule"),
        "-o", os.path.join(runtime_dir, "libSwiftProtobuf.dylib"),
        *sorted(glob.glob(os.path.join(checkout, "Sources", "SwiftProtobuf", "*.swift"))),
    ])

    runtime = [
        "-I", runtime_dir, "-L", runtime_dir, "-lSwiftProtobuf",
        "-Xlinker", "-rpath", "-Xlinker", runtime_dir,
    ]

    # Visibility=public: the two protos live in separate Swift modules, so the generated
    # types have to be visible across the module boundary this experiment is about.
    common_opts = "Visibility=public" + (f",{GEN_OPTS}" if GEN_OPTS else "")

    print("==> generating")
    plugin = f"--plugin=protoc-gen-swift={os.path.join(bin_path, 'protoc-gen-swift')}"
    protos = os.path.join(HERE, "protos")
    gen = os.path.join(OUT, "gen")
    run([protoc, plugin, f"--swift_out={common_opts}:{gen}",
         "-I", protos, os.path.join(protos, "common.proto")])
    run([protoc, plugin,
         f"--swift_out=ProtoPathModuleMappings={os.path.join(HERE, 'module-map.asciipb')},{common_opts}:{gen}",
         "-I", protos, os.path.join(protos, "app.proto")])

    app_pb = os.path.join(gen, "app.pb.swift")
    if "import Common\n" not in read(app_pb):
        print("error: app.pb.swift does not import Common; module mapping did not apply", file=sys.stderr)
        for i, line in enumerate(read(app_pb).splitlines(), 1):
            if line.startswith("import"):
                print(f"{i}:{line}", file=sys.stderr)
        return 1

    write(os.path.join(OUT, "main.swift"), MAIN_SWIFT)

    print()
    results = os.path.join(OUT, "results.kv")
    with open(results, "w") as handle:
        for linkage in ("static", "dynamic"):
            for binding in ("strong", "weak"):
                print(f"==> {linkage} / {binding}")
                build_variant(handle, linkage, binding, runtime)
        print("==> dynamic / weak, dependency omitted at runtime")
        omitted(handle, runtime)

    print()
    collate(results)
    return 0


if __name__ == "__main__":
    sys.exit(main())
