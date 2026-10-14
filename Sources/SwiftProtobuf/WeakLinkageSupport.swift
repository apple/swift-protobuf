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

/// A thread-safe cache for dynamic symbol lookups using `dlsym`.
package final class DynamicSymbolCache: @unchecked Sendable {
    package typealias SymbolProvider = @Sendable (String) -> UnsafeMutableRawPointer?

    private enum SymbolResult {
        case resolved(UnsafeMutableRawPointer)
        case missing
    }

    private static let defaultSymbolProvider: SymbolProvider = { symbolName in
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Bionic)
        return dlsym(rtldDefault, symbolName)
        #else
        return nil
        #endif
    }

    private let lock = Lock()
    private var cache = [String: SymbolResult]()
    private var symbolProvider: SymbolProvider = defaultSymbolProvider

    package static let shared = DynamicSymbolCache()

    func lookup(named symbolName: String) -> UnsafeMutableRawPointer? {
        lock.withLock {
            if let result = cache[symbolName] {
                switch result {
                case .resolved(let ptr):
                    return ptr
                case .missing:
                    return nil
                }
            }

            if let symbol = symbolProvider(symbolName) {
                cache[symbolName] = .resolved(symbol)
                return symbol
            } else {
                cache[symbolName] = .missing
                return nil
            }
        }
    }

    package var countForTesting: Int {
        lock.withLock { cache.count }
    }

    package func resetForTesting(symbolProvider: SymbolProvider? = nil) {
        lock.withLock {
            cache.removeAll()
            self.symbolProvider = symbolProvider ?? Self.defaultSymbolProvider
        }
    }
}

extension MessageSchema {
    /// Resolves the message schema for a generated message type via its getter thunk,
    /// while retaining the concrete witness and map witness thunks when the nominal
    /// type's `.pb.o` object file is linked.
    @_spi(ForGeneratedCodeOnly)
    @inline(never)
    public static func resolveGenerated(
        getter: DynamicLookupThunk,
        witnessThunk: DynamicLookupThunk,
        mapWitnessThunk: DynamicMapWitnessThunk
    ) -> MessageSchema {
        // Packing `witnessThunk` and `mapWitnessThunk` into the stack tuple passed by
        // pointer to the indirect `getter` call prevents Function Signature Optimization
        // from stripping those parameters while `getter` writes the resolved schema to
        // offset 0 (`context.0`).
        var context: (MessageSchema?, DynamicLookupThunk, DynamicMapWitnessThunk) = (
            nil, witnessThunk, mapWitnessThunk
        )
        withUnsafeMutablePointer(to: &context) { pointer in
            getter(pointer)
        }
        return context.0!
    }

    /// Dynamically looks up a message schema based on the name of a generated
    /// accessor function.
    ///
    /// Returns nil if the symbol is not found (i.e., if it has been dropped by the
    /// linker).
    @_spi(ForGeneratedCodeOnly)
    public static func resolveLazy(named symbolName: String) -> MessageSchema? {
        guard let symbol = DynamicSymbolCache.shared.lookup(named: symbolName) else { return nil }
        let resolver = unsafeBitCast(symbol, to: DynamicLookupThunk.self)
        var schema: MessageSchema? = nil
        withUnsafeMutablePointer(to: &schema) { schemaPointer in resolver(schemaPointer) }
        return schema
    }

    /// Dynamically looks up a message witness function based on the name of a generated
    /// accessor function.
    ///
    /// Returns nil if the symbol is not found (i.e., if it has been dropped by the
    /// linker).
    @_spi(ForGeneratedCodeOnly)
    public static func resolveLazyWitness(named symbolName: StaticString) -> InvokeWitnessFunction? {
        guard symbolName.utf8CodeUnitCount > 0 else { return nil }
        let name = symbolName.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
        guard let symbol = DynamicSymbolCache.shared.lookup(named: name) else { return nil }
        let resolver = unsafeBitCast(symbol, to: DynamicLookupThunk.self)
        var witness: InvokeWitnessFunction? = nil
        withUnsafeMutablePointer(to: &witness) { witnessPointer in resolver(witnessPointer) }
        return witness
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
        guard let symbol = DynamicSymbolCache.shared.lookup(named: symbolName) else { return nil }
        let resolver = unsafeBitCast(symbol, to: DynamicMapWitnessThunk.self)
        var witness: InvokeWitnessFunction? = nil
        withUnsafeMutablePointer(to: &witness) { witnessPointer in
            resolver(keyKind.rawValue, witnessPointer)
        }
        return witness
    }

    /// Creates a message schema for a map entry with a lazily-resolved submessage value.
    @_spi(ForGeneratedCodeOnly)
    public static func forLazyMapEntry(
        schema: StaticString,
        keyKind: ProtobufMapKeyKind,
        mapWitnessNamed witnessSymbol: String,
        messageSchemaNamed schemaSymbol: String
    ) -> MessageSchema? {
        let invokeWitness =
            resolveLazyMapWitness(named: witnessSymbol, keyKind: keyKind)
            ?? (resolveLazy(named: schemaSymbol) != nil
                ? SwiftProtobuf_ImplicitWeakMessage._protobuf_mapWitness(for: keyKind)
                : nil)
        return forMapEntry(
            schema: schema,
            invokeWitness: invokeWitness,
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
        let invokeWitness =
            resolveLazyMapWitness(named: witnessSymbol, keyKind: keyKind)
            ?? (EnumSchema.resolveLazy(named: schemaSymbol) != nil
                ? SwiftProtobuf_ImplicitWeakEnum._protobuf_mapWitness(for: keyKind)
                : nil)
        return forMapEntry(
            schema: schema,
            invokeWitness: invokeWitness,
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
    /// Resolves the enum schema for a generated enum type via its getter thunk,
    /// while retaining the concrete witness and map witness thunks when the nominal
    /// type's `.pb.o` object file is linked.
    @_spi(ForGeneratedCodeOnly)
    @inline(never)
    public static func resolveGenerated(
        getter: DynamicLookupThunk,
        witnessThunk: DynamicLookupThunk,
        mapWitnessThunk: DynamicMapWitnessThunk
    ) -> EnumSchema {
        // Packing `witnessThunk` and `mapWitnessThunk` into the stack tuple passed by
        // pointer to the indirect `getter` call prevents Function Signature Optimization
        // from stripping those parameters while `getter` writes the resolved schema to
        // offset 0 (`context.0`).
        var context: (EnumSchema?, DynamicLookupThunk, DynamicMapWitnessThunk) = (
            nil, witnessThunk, mapWitnessThunk
        )
        withUnsafeMutablePointer(to: &context) { pointer in
            getter(pointer)
        }
        return context.0!
    }

    /// Dynamically looks up an enum schema based on the name of a generated
    /// accessor function.
    ///
    /// Returns nil if the symbol is not found (i.e., if it has been dropped by the
    /// linker).
    @_spi(ForGeneratedCodeOnly)
    public static func resolveLazy(named symbolName: String) -> EnumSchema? {
        guard let symbol = DynamicSymbolCache.shared.lookup(named: symbolName) else { return nil }
        let resolver = unsafeBitCast(symbol, to: DynamicLookupThunk.self)
        var schema: EnumSchema? = nil
        withUnsafeMutablePointer(to: &schema) { schemaPointer in resolver(schemaPointer) }
        return schema
    }

    /// Dynamically looks up an enum witness function based on the name of a generated
    /// accessor function.
    ///
    /// Returns nil if the symbol is not found (i.e., if it has been dropped by the
    /// linker).
    @_spi(ForGeneratedCodeOnly)
    public static func resolveLazyWitness(named symbolName: StaticString) -> InvokeWitnessFunction? {
        guard symbolName.utf8CodeUnitCount > 0 else { return nil }
        let name = symbolName.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
        guard let symbol = DynamicSymbolCache.shared.lookup(named: name) else { return nil }
        let resolver = unsafeBitCast(symbol, to: DynamicLookupThunk.self)
        var witness: InvokeWitnessFunction? = nil
        withUnsafeMutablePointer(to: &witness) { witnessPointer in resolver(witnessPointer) }
        return witness
    }
}

#if canImport(Darwin)
/// Dynamically looks up the compressed reflection data string based on the name of a
/// generated accessor function.
///
/// On Darwin, generated `live_support` stubs in `.pbschema.swift` reference both this
/// function and their type's `_getReflection` thunk by storing their function pointers
/// into an output buffer. Under `-dead_strip`, those `live_support` stubs (and the
/// reflection thunks they reference) are retained if and only if this function is live
/// in the binary.
@_spi(ForGeneratedCodeOnly)
@inline(never)
public func _protobuf_resolveReflection(named symbolName: StaticString) -> StaticString? {
    guard symbolName.utf8CodeUnitCount > 0 else { return nil }
    let name = symbolName.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
    guard let symbol = DynamicSymbolCache.shared.lookup(named: name) else { return nil }
    let resolver = unsafeBitCast(symbol, to: MessageSchema.DynamicLookupThunk.self)
    var reflection: StaticString? = nil
    withUnsafeMutablePointer(to: &reflection) { reflectionPointer in
        resolver(reflectionPointer)
    }
    return reflection
}
#endif
