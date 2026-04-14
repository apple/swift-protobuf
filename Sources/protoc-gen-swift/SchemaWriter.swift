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
    /// Contains the Swift string literal (without quotes) that encodes the schema in the generated
    /// source.
    var schemaCode: String = ""

    /// Appends the given integer to the encoded schema literal in base 128 format, using the given
    /// number of bytes to represent it.
    mutating func writeBase128Int(_ value: UInt64, byteWidth: Int) {
        func append(_ value: UInt64) {
            // Print the normal scalar if it's ASCII-printable so that we only use longer `\u{...}`
            // sequences for those that are not.
            if value == 0 {
                schemaCode.append("\\0")
            } else if isprint(Int32(truncatingIfNeeded: value)) != 0 {
                self.append(escapingIfNecessary: UnicodeScalar(UInt32(truncatingIfNeeded: value))!)
            } else {
                schemaCode.append(String(format: "\\u{%x}", value))
            }
        }
        var v = value
        for _ in 0..<byteWidth {
            append(v & 0x7f)
            v &>>= 7
        }
    }

    /// Appends the given string to the encoded schema literal, escaping any characters as needed.
    ///
    /// - Precondition: This method assumes that the string does not contain any nonprintable or
    ///   control characters.
    mutating func writeString(_ value: String) {
        for scalar in value.unicodeScalars {
            append(escapingIfNecessary: scalar)
        }
    }

    /// Appends the given Unicode scalar to the bytecode literal, escaping it if necessary for use
    /// in Swift code.
    private mutating func append(escapingIfNecessary scalar: Unicode.Scalar) {
        switch scalar {
        case "\\", "\"":
            schemaCode.unicodeScalars.append("\\")
            schemaCode.unicodeScalars.append(scalar)
        default:
            schemaCode.unicodeScalars.append(scalar)
        }
    }
}
