// Sources/SwiftProtobuf/WireFormat.swift - Describes proto wire formats
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Types related to binary wire formats of encoded values.
///
// -----------------------------------------------------------------------------

/// Denotes the wire format by which a value is encoded in binary form.
internal enum WireFormat: UInt8 {

  case varint = 0
  case fixed64 = 1
  case lengthDelimited = 2
  case startGroup = 3
  case endGroup = 4
  case fixed32 = 5
}
