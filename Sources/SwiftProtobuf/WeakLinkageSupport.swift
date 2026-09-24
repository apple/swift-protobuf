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
private var rtldDefault: UnsafeMutableRawPointer? { .init(bitPattern: UInt(0xFFFF_FFFF)) }
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

    /// Dynamically looks up a map witness function based on the name of a generated
    /// accessor function.
    ///
    /// Returns nil if the symbol is not found (i.e., if it has been dropped by the
    /// linker).
    @_spi(ForGeneratedCodeOnly)
    public static func resolveLazyMapWitness(
        named symbolName: String,
        keyKind: ProtobufMapKeyKind
    ) -> InvokeWitnessFunction? {
        // TODO: Put a cache around this.
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Bionic)
        guard let symbol = dlsym(rtldDefault, symbolName) else { return nil }
        typealias Resolver = @convention(c) (UInt8, UnsafeMutableRawPointer) -> Void
        let resolver = unsafeBitCast(symbol, to: Resolver.self)
        var witness: InvokeWitnessFunction? = nil
        withUnsafeMutablePointer(to: &witness) { witnessPointer in
            resolver(keyKind.rawValue, witnessPointer)
        }
        return witness
        #else
        return nil
        #endif
    }

    /// Creates a message schema for a map entry with a lazily-resolved submessage value.
    @_spi(ForGeneratedCodeOnly)
    public static func forLazyMapEntry(
        schema: StaticString,
        keyKind: ProtobufMapKeyKind,
        mapWitnessNamed witnessSymbol: String,
        messageSchemaNamed schemaSymbol: String
    ) -> MessageSchema? {
        forMapEntry(
            schema: schema,
            invokeWitness: resolveLazyMapWitness(named: witnessSymbol, keyKind: keyKind),
            submessageOrEnumResolver: { token in
                guard token.index == 1 else {
                    preconditionFailure("This should have been unreachable; this is a generator bug")
                }
                return resolveLazy(named: schemaSymbol).map(SubmessageOrEnumSchema.message)
            }
        )
    }

    /// Creates a message schema for a map entry with a lazily-resolved enum value.
    @_spi(ForGeneratedCodeOnly)
    public static func forLazyMapEntry(
        schema: StaticString,
        keyKind: ProtobufMapKeyKind,
        mapWitnessNamed witnessSymbol: String,
        enumSchemaNamed schemaSymbol: String
    ) -> MessageSchema? {
        forMapEntry(
            schema: schema,
            invokeWitness: resolveLazyMapWitness(named: witnessSymbol, keyKind: keyKind),
            submessageOrEnumResolver: { token in
                guard token.index == 1 else {
                    preconditionFailure("This should have been unreachable; this is a generator bug")
                }
                return EnumSchema.resolveLazy(named: schemaSymbol).map(SubmessageOrEnumSchema.enum)
            }
        )
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
