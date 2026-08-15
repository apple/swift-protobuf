#!/usr/bin/env python3
#
# Benchmarks/gen-synthetic.py - generate the per-field-type synthetic workloads.
#
# Copyright (c) 2014 - 2026 Apple Inc. and the project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See LICENSE.txt for license information:
# https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
#
# -----------------------------------------------------------------------------
#
# For each protobuf field type, this emits a message with FIELD_COUNT fields of only
# that type. It also emits a fixture of pre-encoded messages and the Swift call that
# runs it. One field type per message makes the per-type table readable. A regression
# then shows against exactly one row.
#
# Python encodes the fixtures here, rather than Swift populating and serializing
# messages. This keeps the encoder under test out of the process that produces its own
# input. The Swift side then needs no generated population code. It decodes the fixture
# and re-encodes what it decoded, the same as the CatalogEntry workload.
#
# Run this after you change FIELD_COUNT or the type list. Then commit the output.
#
# -----------------------------------------------------------------------------

import pathlib
import struct

HERE = pathlib.Path(__file__).parent

# Fields per message. This is large enough that per-field dispatch dominates the
# per-message overhead. It is small enough to keep the checked-in fixtures tiny.
FIELD_COUNT = 16

# Messages per fixture.
MESSAGE_COUNT = 8

# Elements per repeated field.
REPEATED_COUNT = 16


# MARK: - protobuf wire format

def varint(value):
    """Encodes an unsigned varint."""
    out = bytearray()
    while True:
        byte = value & 0x7F
        value >>= 7
        if value:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            return bytes(out)


def signed_varint(value):
    """Encodes a signed varint using two's complement, as int32/int64 do."""
    return varint(value & 0xFFFFFFFFFFFFFFFF)


def zigzag(value, bits):
    return varint(((value << 1) ^ (value >> (bits - 1))) & ((1 << bits) - 1))


def tag(field, wire_type):
    return varint((field << 3) | wire_type)


VARINT, FIXED64, LENGTH, FIXED32 = 0, 1, 2, 5


def delimited(payload):
    return varint(len(payload)) + payload


# MARK: - field type table

# Each entry: proto type, wire type, and a function producing the encoded *value*
# (no tag) for the nth field of the mth message.
def _sub_message(n, m):
    # SubMessage { int32 value = 1; }
    return delimited(tag(1, VARINT) + signed_varint(n * 7 + m))


SCALARS = [
    # (name, proto type, wire type, value encoder)
    ("Int32", "int32", VARINT, lambda n, m: signed_varint(n * 11 + m + 1)),
    ("Int64", "int64", VARINT, lambda n, m: signed_varint((n * 11 + m + 1) << 20)),
    ("UInt32", "uint32", VARINT, lambda n, m: varint(n * 13 + m + 1)),
    ("UInt64", "uint64", VARINT, lambda n, m: varint((n * 13 + m + 1) << 20)),
    ("SInt32", "sint32", VARINT, lambda n, m: zigzag(-(n * 17 + m + 1), 32)),
    ("SInt64", "sint64", VARINT, lambda n, m: zigzag(-((n * 17 + m + 1) << 20), 64)),
    ("Fixed32", "fixed32", FIXED32, lambda n, m: struct.pack("<I", n * 19 + m + 1)),
    ("Fixed64", "fixed64", FIXED64, lambda n, m: struct.pack("<Q", (n * 19 + m + 1) << 20)),
    ("SFixed32", "sfixed32", FIXED32, lambda n, m: struct.pack("<i", -(n * 23 + m + 1))),
    ("SFixed64", "sfixed64", FIXED64, lambda n, m: struct.pack("<q", -((n * 23 + m + 1) << 20))),
    ("Float", "float", FIXED32, lambda n, m: struct.pack("<f", n + m * 0.5 + 1.25)),
    ("Double", "double", FIXED64, lambda n, m: struct.pack("<d", n + m * 0.5 + 1.25)),
    ("Bool", "bool", VARINT, lambda n, m: varint(1)),
    # 24 bytes. This is long enough to exercise the copy. It is short enough to stay
    # in the small ranges that most real string fields occupy.
    ("String", "string", LENGTH, lambda n, m: delimited(f"field-{n:02d}-msg-{m:02d}-xx".encode())),
    ("Bytes", "bytes", LENGTH, lambda n, m: delimited(bytes([(n + m + i) & 0xFF for i in range(24)]))),
    ("Enum", "SubEnum", VARINT, lambda n, m: varint((n + m) % 4)),
    ("Message", "SubMessage", LENGTH, _sub_message),
]

# Repeated variants. Numeric ones are packed, the proto3 default. This is the path to
# watch most. It should be the cheapest per element.
REPEATED = [
    ("RepeatedInt32", "int32", True, VARINT, lambda n, m, i: signed_varint(i * 11 + n + m + 1)),
    ("RepeatedDouble", "double", True, FIXED64, lambda n, m, i: struct.pack("<d", i + n + m * 0.5)),
    ("RepeatedString", "string", False, LENGTH, lambda n, m, i: delimited(f"elem-{i:02d}-{n:02d}-{m:02d}".encode())),
    ("RepeatedMessage", "SubMessage", False, LENGTH, lambda n, m, i: _sub_message(n + i, m)),
]


def encode_scalar_message(wire_type, value_for, message_index):
    out = bytearray()
    for field in range(1, FIELD_COUNT + 1):
        out += tag(field, wire_type)
        out += value_for(field, message_index)
    return bytes(out)


def encode_repeated_message(packed, wire_type, value_for, message_index):
    out = bytearray()
    for field in range(1, FIELD_COUNT + 1):
        elements = [value_for(field, message_index, i) for i in range(REPEATED_COUNT)]
        if packed:
            out += tag(field, LENGTH) + delimited(b"".join(elements))
        else:
            for element in elements:
                out += tag(field, wire_type) + element
    return bytes(out)


# Row label for the results table. This is the .proto spelling of the field type, not
# the name of the synthetic wrapper message.
DISPLAY_NAMES = {"SubEnum": "enum", "SubMessage": "message"}


def display(proto_type):
    for placeholder, spelling in DISPLAY_NAMES.items():
        proto_type = proto_type.replace(placeholder, spelling)
    return proto_type


def length_delimited_stream(messages):
    return b"".join(delimited(m) for m in messages)


# MARK: - emit

def main():
    protos = ["""// Benchmarks/protos/synthetic.proto - GENERATED by gen-synthetic.py; do not edit.
//
// One message per field type, each with only that type. A per-type timing table then
// attributes a regression to exactly one row.

syntax = "proto3";
package synthetic;

enum SubEnum {
    ZERO = 0;
    FOO = 1;
    BAR = 2;
    BAZ = 3;
}

message SubMessage {
    int32 value = 1;
}
"""]
    workloads = []
    fixtures_dir = HERE / "fixtures"

    for name, proto_type, wire_type, value_for in SCALARS:
        fields = "\n".join(
            f"    {proto_type} f{n} = {n};" for n in range(1, FIELD_COUNT + 1)
        )
        protos.append(f"message Perf{name} {{\n{fields}\n}}\n")
        stream = length_delimited_stream([
            encode_scalar_message(wire_type, value_for, m) for m in range(MESSAGE_COUNT)
        ])
        (fixtures_dir / f"synthetic_{name}.pb").write_bytes(stream)
        workloads.append((name, display(proto_type)))

    for name, proto_type, packed, wire_type, value_for in REPEATED:
        fields = "\n".join(
            f"    repeated {proto_type} f{n} = {n};" for n in range(1, FIELD_COUNT + 1)
        )
        protos.append(f"message Perf{name} {{\n{fields}\n}}\n")
        stream = length_delimited_stream([
            encode_repeated_message(packed, wire_type, value_for, m)
            for m in range(MESSAGE_COUNT)
        ])
        (fixtures_dir / f"synthetic_{name}.pb").write_bytes(stream)
        workloads.append((name, display(f"repeated {proto_type}")))

    (HERE / "protos" / "synthetic.proto").write_text("\n".join(protos))

    lines = [
        "// Benchmarks/Sources/SyntheticWorkloads.swift - GENERATED by gen-synthetic.py; do not edit.",
        "//",
        "// Copyright (c) 2014 - 2026 Apple Inc. and the project authors",
        "// Licensed under Apache License v2.0 with Runtime Library Exception",
        "//",
        "// See LICENSE.txt for license information:",
        "// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt",
        "",
        "/// Runs one workload per protobuf field type. Each message carries "
        f"{FIELD_COUNT} fields of a",
        "/// single type. A slow row then names the field type responsible.",
        "func runSyntheticWorkloads() throws {",
    ]
    for name, description in workloads:
        lines.append(
            f'    try run(Synthetic_Perf{name}.self, named: "{description}", '
            f'fixtures: try FixtureLoader.named("synthetic_{name}.pb"))'
        )
    lines.append("}")
    (HERE / "Sources" / "SyntheticWorkloads.swift").write_text("\n".join(lines) + "\n")

    print(f"wrote protos/synthetic.proto ({len(workloads)} messages)")
    print(f"wrote {len(workloads)} fixtures to fixtures/")
    print("wrote Sources/SyntheticWorkloads.swift")


if __name__ == "__main__":
    main()
