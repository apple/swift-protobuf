// Sources/protoc-gen-swift/SchemaWriter.swift - Low-level schema writer
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Low-level logic used by other schema calculators to write the 7-bit encoding
/// needed for `StaticString`.
///
// -----------------------------------------------------------------------------

import Foundation

/// Manages the generation of a schema string for a single platform.
struct SchemaWriter {
    /// Contains the raw UTF-8 bytes of the encoded schema.
    private(set) var bytes: [UInt8] = []

    /// Returns the Swift string literal (without quotes) that encodes the schema in the generated
    /// source.
    var schemaCode: String {
        var result = ""
        for byte in bytes {
            // Print the normal scalar if it's ASCII-printable so that we only use longer `\u{...}`
            // sequences for those that are not.
            if byte == 0 {
                result.append("\\0")
            } else if isprint(Int32(byte)) != 0 {
                let scalar = Unicode.Scalar(byte)
                switch scalar {
                case "\\", "\"":
                    result.unicodeScalars.append("\\")
                    result.unicodeScalars.append(scalar)
                default:
                    result.unicodeScalars.append(scalar)
                }
            } else {
                result.append(String(format: "\\u{%x}", byte))
            }
        }
        return result
    }

    /// Appends the given integer to the encoded schema in base 128 format, using the given
    /// number of bytes to represent it.
    mutating func writeBase128Int(_ value: UInt64, byteWidth: Int) {
        var v = value
        for _ in 0..<byteWidth {
            bytes.append(UInt8(truncatingIfNeeded: v & 0x7f))
            v &>>= 7
        }
    }

    /// Appends the UTF-8 bytes of the given string to the encoded schema.
    mutating func writeString(_ value: String) {
        bytes.append(contentsOf: value.utf8)
    }
}
