#!/usr/bin/env python3
#
# Benchmarks/weaklink/generate.py - emit the two-module proto fixture.
#
# Copyright (c) 2014 - 2026 Apple Inc. and the project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See LICENSE.txt for license information:
# https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
#
# -----------------------------------------------------------------------------
#
# `Common` holds many message types; `App` references exactly one of them. That is
# the shape a real app has -- a large shared proto module of which any one client
# touches a small fraction -- and it is the shape @_weakLinked import is supposed to
# let the linker exploit.
#
# -----------------------------------------------------------------------------

import pathlib

HERE = pathlib.Path(__file__).parent

# Message types in the shared module. Only COMMON_TYPES[0] is ever referenced.
COMMON_TYPES = 40

# Fields per shared message, so each unused type carries real code weight.
FIELDS_PER_TYPE = 12

FIELD_TYPES = [
    "int32", "int64", "uint32", "uint64", "sint32", "sint64",
    "fixed32", "double", "bool", "string", "bytes", "float",
]


def main():
    protos = HERE / "protos"
    protos.mkdir(exist_ok=True)

    common = ['syntax = "proto3";', "package common;", ""]
    for index in range(COMMON_TYPES):
        common.append(f"message Shared{index:02d} {{")
        for field in range(FIELDS_PER_TYPE):
            proto_type = FIELD_TYPES[field % len(FIELD_TYPES)]
            common.append(f"    {proto_type} f{field} = {field + 1};")
        common.append("}")
        common.append("")
    (protos / "common.proto").write_text("\n".join(common))

    # The app message references Shared00 and nothing else in `common`.
    (protos / "app.proto").write_text(
        'syntax = "proto3";\n'
        "package app;\n"
        "\n"
        'import "common.proto";\n'
        "\n"
        "message Envelope {\n"
        "    int64 id = 1;\n"
        "    common.Shared00 payload = 2;\n"
        "}\n"
    )

    # Tells protoc-gen-swift that common.proto lives in the `Common` Swift module, so
    # app.pb.swift emits `import Common` -- the import this experiment weakens.
    (HERE / "module-map.asciipb").write_text(
        "mapping {\n"
        '  module_name: "Common"\n'
        '  proto_file_path: "common.proto"\n'
        "}\n"
    )

    print(f"wrote protos/common.proto ({COMMON_TYPES} types x {FIELDS_PER_TYPE} fields)")
    print("wrote protos/app.proto, module-map.asciipb")


if __name__ == "__main__":
    main()
