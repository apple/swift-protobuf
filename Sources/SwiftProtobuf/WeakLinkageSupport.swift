// Sources/SwiftProtobuf/WeakLinkageSupport.swift - Dynamic lookup for weak linkage
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Dynamic symbol resolution functions to support weak-linked protobuf modules.
///
// -----------------------------------------------------------------------------

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
@preconcurrency import Glibc
#elseif canImport(Musl)
@preconcurrency import Musl
#elseif canImport(Bionic)
@preconcurrency import Bionic
#endif

// These constants are equal to the `RTLD_DEFAULT` value from dlfcn.h on each
// platform. That C constant cannot be reliably referenced from Swift because
// Linux only defines it when `_GNU_SOURCE` is defined, so we repeat it here.
#if canImport(Darwin) || os(FreeBSD) || os(OpenBSD)
private var rtldDefault: UnsafeMutableRawPointer? { .init(bitPattern: -2) }
#elseif os(Android) && _pointerBitWidth(_32)
private var rtldDefault: UnsafeMutableRawPointer? { .init(bitPattern: UInt(0xFFFFFFFF)) }
#elseif os(Linux) || os(Android)
private var rtldDefault: UnsafeMutableRawPointer? { .init(bitPattern: 0) }
#endif

extension MessageSchema {
    /// Dynamically looks up a message schema based on the name of a generated
    /// accessor function.
    ///
    /// Returns nil if the symbol is not found (i.e., if it has been dropped by the
    /// linker).
    @_spi(ForGeneratedCodeOnly)
    public static func resolveLazy(named symbolName: String) -> MessageSchema? {
        // TODO: Put a cache around this.
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Bionic)
        guard let symbol = dlsym(rtldDefault, symbolName) else { return nil }
        typealias Resolver = @convention(c) (UnsafeMutableRawPointer) -> Void
        let resolver = unsafeBitCast(symbol, to: Resolver.self)
        var schema: MessageSchema? = nil
        withUnsafeMutablePointer(to: &schema) { schemaPointer in resolver(schemaPointer) }
        return schema
        #else
        return nil
        #endif
    }
}

extension EnumSchema {
    /// Dynamically looks up an enum schema based on the name of a generated
    /// accessor function.
    ///
    /// Returns nil if the symbol is not found (i.e., if it has been dropped by the
    /// linker).
    @_spi(ForGeneratedCodeOnly)
    public static func resolveLazy(named symbolName: String) -> EnumSchema? {
        // TODO: Put a cache around this.
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Bionic)
        guard let symbol = dlsym(rtldDefault, symbolName) else { return nil }
        typealias Resolver = @convention(c) (UnsafeMutableRawPointer) -> Void
        let resolver = unsafeBitCast(symbol, to: Resolver.self)
        var schema: EnumSchema? = nil
        withUnsafeMutablePointer(to: &schema) { schemaPointer in resolver(schemaPointer) }
        return schema
        #else
        return nil
        #endif
    }
}
