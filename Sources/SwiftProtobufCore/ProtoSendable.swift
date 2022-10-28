// Sources/SwiftProtobuf/ProtoSendable.swift - Support for accessing proto names
//
// Copyright (c) 2014 - 2022 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

#if swift(>=5.5) && canImport(_Concurrency)
/// SwiftProtobuf Internal: Compatibility alias for indicating a value can be safely used in concurrent code.
public typealias _ProtoSendable = Swift.Sendable
#else
/// SwiftProtobuf Internal: Compatibility alias for indicating a value can be safely used in concurrent code.
///
/// When using a compiler that does not support concurrency, this declaration does nothing.
public typealias _ProtoSendable = Any
#endif
