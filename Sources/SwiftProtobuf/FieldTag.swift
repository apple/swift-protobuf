// SwiftProtobuf/Sources/SwiftProtobuf/FieldTag.swift - Describes a binary field tag
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// Types related to binary encoded tags (field numbers and wire formats).
///
// -----------------------------------------------------------------------------


/// Encapsulates the number and wire format of a field, which together form the
/// "tag".
internal struct FieldTag: RawRepresentable {

  typealias RawValue = UInt32

  /// The raw numeric value of the tag, which contains both the field number and
  /// wire format.
  let rawValue: UInt32

  /// The field number component of the tag.
  var fieldNumber: Int {
    return Int(rawValue >> 3)
  }

  /// The wire format component of the tag.
  var wireFormat: WireFormat {
    // This force-unwrap is safe because there are only two initialization
    // paths: one that takes a WireFormat directly (and is guaranteed valid at
    // compile-time), or one that takes a raw value but which only lets valid
    // wire formats through.
    return WireFormat(rawValue: UInt8(rawValue & 7))!
  }

  /// A helper property that returns the number of bytes required to
  /// varint-encode this tag.
  var encodedSize: Int {
    return Varint.encodedSize(of: rawValue)
  }

  /// Creates a new tag from its raw numeric representation.
  ///
  /// Note that if the raw value given here is not a valid tag (for example, it
  /// has an invalid wire format), this initializer will fail.
  init?(rawValue: UInt32) {
    // Verify that the wire format is valid and fail if it is not.
    guard let _ = WireFormat(rawValue: UInt8(rawValue % 8)) else {
      return nil
    }
    self.rawValue = rawValue
  }

  /// Creates a new tag by composing the given field number and wire format.
  init(fieldNumber: Int, wireFormat: WireFormat) {
    self.rawValue = UInt32(truncatingBitPattern: fieldNumber) << 3 |
      UInt32(wireFormat.rawValue)
  }
}
