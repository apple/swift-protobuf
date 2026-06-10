// Sources/SwiftProtobuf/UTF8Name.swift - Lightweight UTF-8 name wrapper
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A lightweight wrapper around a buffer of UTF-8 code units representing a name,
/// used to avoid string materialization overhead.
///
// -----------------------------------------------------------------------------

/// An immutable UTF-8 view of a message name, field name, or enum case.
///
/// Since the strings owned by the schemas and reflection tables are effectively immortal once
/// defined and/or decompressed, we can pass around UTF-8 buffers directly without concern for the
/// lifetimes of these values. This type is very similar in spirit to the recently added `UTF8Span`
/// (which we can't use yet since it's too new).
package struct UTF8Name: @unchecked Sendable {
    let buffer: UnsafeBufferPointer<UTF8.CodeUnit>

    init(start: UnsafePointer<UTF8.CodeUnit>, count: Int) {
        self.buffer = UnsafeBufferPointer(start: start, count: count)
    }

    init(start: UnsafeRawPointer, count: Int) {
        self.buffer =
            UnsafeRawBufferPointer(start: start, count: count).bindMemory(to: UTF8.CodeUnit.self)
    }
}

extension UTF8Name: Equatable {
    package static func == (lhs: UTF8Name, rhs: UTF8Name) -> Bool {
        lhs.buffer.elementsEqual(rhs.buffer)
    }
}

extension UTF8Name: Hashable {
    package func hash(into hasher: inout Hasher) {
        for byte in buffer {
            hasher.combine(byte)
        }
    }
}

extension UTF8Name {
    /// Returns true if the code units in the receiver are equal to the UTF-8 code units of the
    /// given string.
    ///
    /// This is used when binary searching name tables for arbitrary strings.
    package func utf8CodeUnitsEqual(_ other: String) -> Bool {
        buffer.elementsEqual(other.utf8)
    }

    /// Returns true if the receiver lexicographically precedes the given string.
    ///
    /// This is used when binary searching name tables for arbitrary strings.
    package func lexicographicallyPrecedes(_ other: String) -> Bool {
        var lhsIter = buffer.makeIterator()
        var rhsIter = other.utf8.makeIterator()

        while true {
            switch (lhsIter.next(), rhsIter.next()) {
            case let (l?, r?):
                if l != r { return l < r }
            case (nil, _?):
                return true
            case (_?, nil):
                return false
            case (nil, nil):
                return false
            }
        }
    }

    /// Consumes the given prefix from the receiver and returns the remaining suffix,
    /// or nil if the receiver does not start with the prefix.
    package func consumePrefix(_ prefix: StaticString) -> UTF8Name? {
        let prefixCount = prefix.utf8CodeUnitCount
        guard buffer.count >= prefixCount else { return nil }
        let prefixBuffer = UnsafeBufferPointer(start: prefix.utf8Start, count: prefixCount)
        let currentPrefixBuffer = UnsafeBufferPointer(start: buffer.baseAddress!, count: prefixCount)
        if currentPrefixBuffer.elementsEqual(prefixBuffer) {
            let suffixStart = buffer.baseAddress! + prefixCount
            let suffixCount = buffer.count - prefixCount
            return UTF8Name(start: UnsafeRawPointer(suffixStart), count: suffixCount)
        }
        return nil
    }
}

extension String {
    package init(protobufUTF8Name: UTF8Name) {
        self.init(decoding: protobufUTF8Name.buffer, as: UTF8.self)
    }
}

extension DefaultStringInterpolation {
    package mutating func appendInterpolation(_ value: UTF8Name) {
        appendInterpolation(String(protobufUTF8Name: value))
    }
}
