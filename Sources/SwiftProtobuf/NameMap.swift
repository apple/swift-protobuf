// Sources/SwiftProtobuf/NameMap.swift - Bidirectional number/name mapping
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

/// TODO: Right now, only the NameMap and the NameDescription enum
/// (which are directly used by the generated code) are public.
/// This means that code outside the library has no way to actually
/// use this data.  We should develop and publicize a suitable API
/// for that purpose.  (Which might be the same as the internal API.)

/// This must produce exactly the same outputs as the corresponding
/// code in the protoc-gen-swift code generator. Changing it will
/// break compatibility of the library with older generated code.
///
/// It does not necessarily need to match protoc's JSON field naming
/// logic, however.
private func toJSONFieldName(_ s: UnsafeBufferPointer<UInt8>) -> String {
    var result = String.UnicodeScalarView()
    var capitalizeNext = false
    for c in s {
        if c == UInt8(ascii: "_") {
            capitalizeNext = true
        } else if capitalizeNext {
            result.append(Unicode.Scalar(c).uppercasedAssumingASCII)
            capitalizeNext = false
        } else {
            result.append(Unicode.Scalar(c))
        }
    }
    return String(result)
}
#if !REMOVE_LEGACY_NAMEMAP_INITIALIZERS
private func toJSONFieldName(_ s: StaticString) -> String {
    guard s.hasPointerRepresentation else {
        // If it's a single code point, it wouldn't be changed by the above algorithm.
        // Return it as-is.
        return s.description
    }
    return toJSONFieldName(UnsafeBufferPointer(start: s.utf8Start, count: s.utf8CodeUnitCount))
}
#endif  // !REMOVE_LEGACY_NAMEMAP_INITIALIZERS

/// Allocate static memory buffers to intern UTF-8
/// string data.  Track the buffers and release all of those buffers
/// in case we ever get deallocated.
private class InternPool {
    private var interned = [UnsafeRawBufferPointer]()

    func intern(utf8: String.UTF8View) -> UnsafeRawBufferPointer {
        let mutable = UnsafeMutableRawBufferPointer.allocate(
            byteCount: utf8.count,
            alignment: MemoryLayout<UInt8>.alignment
        )
        mutable.copyBytes(from: utf8)
        let immutable = UnsafeRawBufferPointer(mutable)
        interned.append(immutable)
        return immutable
    }

    func intern(utf8Ptr: UnsafeBufferPointer<UInt8>) -> UnsafeRawBufferPointer {
        let mutable = UnsafeMutableRawBufferPointer.allocate(
            byteCount: utf8Ptr.count,
            alignment: MemoryLayout<UInt8>.alignment
        )
        mutable.copyBytes(from: utf8Ptr)
        let immutable = UnsafeRawBufferPointer(mutable)
        interned.append(immutable)
        return immutable
    }

    deinit {
        for buff in interned {
            buff.deallocate()
        }
    }
}

/// Instructions used in bytecode streams that define proto name mappings.
///
/// Since field and enum case names are encoded in numeric order, field and case number operands in
/// the bytecode are stored as adjacent differences. Most messages/enums use densely packed
/// numbers, so we've optimized the opcodes for that; each instruction that takes a single
/// field/case number has two forms: one that assumes the next number is +1 from the previous
/// number, and a second form that takes an arbitrary delta from the previous number.
///
/// This has package visibility so that it is also visible to the generator.
package enum ProtoNameInstruction: UInt64, CaseIterable {
    /// The proto (text format) name and the JSON name are the same string.
    ///
    /// ## Operands
    /// * (Delta only) An integer representing the (delta from the previous) field or enum case
    ///   number.
    /// * A string containing the single text format and JSON name.
    case sameNext = 1
    case sameDelta = 2

    /// The JSON name can be computed from the proto string.
    ///
    /// ## Operands
    /// * (Delta only) An integer representing the (delta from the previous) field or enum case
    ///   number.
    /// * A string containing the single text format name, from which the JSON name will be
    ///   dynamically computed.
    case standardNext = 3
    case standardDelta = 4

    /// The JSON and text format names are just different.
    ///
    /// ## Operands
    /// * (Delta only) An integer representing the (delta from the previous) field or enum case
    ///   number.
    /// * A string containing the text format name.
    /// * A string containing the JSON name.
    case uniqueNext = 5
    case uniqueDelta = 6

    /// Used for group fields only to represent the message type name of a group.
    ///
    /// ## Operands
    /// * (Delta only) An integer representing the (delta from the previous) field number.
    /// * A string containing the (UpperCamelCase by convention) message type name, from which the
    ///   text format and JSON names can be derived (lowercase).
    case groupNext = 7
    case groupDelta = 8

    /// Used for enum cases only to represent a value's primary proto name (the first defined case)
    /// and its aliases. The JSON and text format names for enums are always the same.
    ///
    /// ## Operands
    /// * (Delta only) An integer representing the (delta from the previous) enum case number.
    /// * An integer `aliasCount` representing the number of aliases.
    /// * A string containing the text format/JSON name (the first defined case with this number).
    /// * `aliasCount` strings containing other text format/JSON names that are aliases.
    case aliasNext = 9
    case aliasDelta = 10

    /// Represents a reserved name in a proto message.
    ///
    /// ## Operands
    /// * The name of a reserved field.
    case reservedName = 11

    /// Represents a range of reserved field numbers or enum case numbers in a proto message.
    ///
    /// ## Operands
    /// * An integer representing the lower bound (inclusive) of the reserved number range.
    /// * An integer representing the delta between the upper bound (exclusive) and the lower bound
    ///   of the reserved number range.
    case reservedNumbers = 12

    /// Indicates whether the opcode represents an instruction that has an explicit delta encoded
    /// as its first operand.
    var hasExplicitDelta: Bool {
        switch self {
        case .sameDelta, .standardDelta, .uniqueDelta, .groupDelta, .aliasDelta: return true
        default: return false
        }
    }
}

/// An immutable bidirectional mapping between field/enum-case names
/// and numbers, used to record field names for text-based
/// serialization (JSON and text).  These maps are lazily instantiated
/// for each message as needed, so there is no run-time overhead for
/// users who do not use text-based serialization formats.
public struct _NameMap: ExpressibleByDictionaryLiteral {

    /// An immutable interned string container.  The `utf8Start` pointer
    /// is guaranteed valid for the lifetime of the `NameMap` that you
    /// fetched it from.  Since `NameMap`s are only instantiated as
    /// immutable static values, that should be the lifetime of the
    /// program.
    ///
    /// Internally, this uses `StaticString` (which refers to a fixed
    /// block of UTF-8 data) where possible.  In cases where the string
    /// has to be computed, it caches the UTF-8 bytes in an
    /// unmovable and immutable heap area.
    package struct Name: Hashable, CustomStringConvertible {
        #if !REMOVE_LEGACY_NAMEMAP_INITIALIZERS
        // This should not be used outside of this file, as it requires
        // coordinating the lifecycle with the lifecycle of the pool
        // where the raw UTF8 gets interned.
        fileprivate init(staticString: StaticString, pool: InternPool) {
            if staticString.hasPointerRepresentation {
                self.utf8Buffer = UnsafeRawBufferPointer(
                    start: staticString.utf8Start,
                    count: staticString.utf8CodeUnitCount
                )
            } else {
                self.utf8Buffer = staticString.withUTF8Buffer { pool.intern(utf8Ptr: $0) }
            }
        }
        #endif  // !REMOVE_LEGACY_NAMEMAP_INITIALIZERS

        // This should not be used outside of this file, as it requires
        // coordinating the lifecycle with the lifecycle of the pool
        // where the raw UTF8 gets interned.
        fileprivate init(string: String, pool: InternPool) {
            let utf8 = string.utf8
            self.utf8Buffer = pool.intern(utf8: utf8)
        }

        // This is for building a transient `Name` object sufficient for lookup purposes.
        // It MUST NOT be exposed outside of this file.
        fileprivate init(transientUtf8Buffer: UnsafeRawBufferPointer) {
            self.utf8Buffer = transientUtf8Buffer
        }

        // This is for building a `Name` object from a slice of a bytecode `StaticString`.
        // It MUST NOT be exposed outside of this file.
        fileprivate init(bytecodeUTF8Buffer: UnsafeBufferPointer<UInt8>) {
            self.utf8Buffer = UnsafeRawBufferPointer(bytecodeUTF8Buffer)
        }

        internal let utf8Buffer: UnsafeRawBufferPointer

        public var description: String {
            String(decoding: self.utf8Buffer, as: UTF8.self)
        }

        public func hash(into hasher: inout Hasher) {
            for byte in utf8Buffer {
                hasher.combine(byte)
            }
        }

        public static func == (lhs: Name, rhs: Name) -> Bool {
            if lhs.utf8Buffer.count != rhs.utf8Buffer.count {
                return false
            }
            return lhs.utf8Buffer.elementsEqual(rhs.utf8Buffer)
        }
    }

    /// The JSON and proto names for a particular field, enum case, or extension.
    internal struct Names {
        private(set) var json: Name?
        private(set) var proto: Name
    }

    #if !REMOVE_LEGACY_NAMEMAP_INITIALIZERS

    /// A description of the names for a particular field or enum case.
    /// The different forms here let us minimize the amount of string
    /// data that we store in the binary.
    ///
    /// These are only used in the generated code to initialize a NameMap.
    public enum NameDescription {

        /// The proto (text format) name and the JSON name are the same string.
        case same(proto: StaticString)

        /// The JSON name can be computed from the proto string
        case standard(proto: StaticString)

        /// The JSON and text format names are just different.
        case unique(proto: StaticString, json: StaticString)

        /// Used for enum cases only to represent a value's primary proto name (the
        /// first defined case) and its aliases. The JSON and text format names for
        /// enums are always the same.
        case aliased(proto: StaticString, aliases: [StaticString])
    }

    #endif  // !REMOVE_LEGACY_NAMEMAP_INITIALIZERS

    private var internPool = InternPool()

    /// The mapping from field/enum-case numbers to names.
    private var numberToNameMap: [Int: Names] = [:]

    /// The mapping from proto/text names to field/enum-case numbers.
    private var protoToNumberMap: [Name: Int] = [:]

    /// The mapping from JSON names to field/enum-case numbers.
    /// Note that this also contains all of the proto/text names,
    /// as required by Google's spec for protobuf JSON.
    private var jsonToNumberMap: [Name: Int] = [:]

    /// The reserved names in for this object. Currently only used for Message to
    /// support TextFormat's requirement to skip these names in all cases.
    private var reservedNames: [String] = []

    /// The reserved numbers in for this object. Currently only used for Message to
    /// support TextFormat's requirement to skip these numbers in all cases.
    private var reservedRanges: [Range<Int32>] = []

    /// Creates a new empty field/enum-case name/number mapping.
    public init() {}

    #if REMOVE_LEGACY_NAMEMAP_INITIALIZERS

    // Provide a dummy for ExpressibleByDictionaryLiteral conformance.
    public init(dictionaryLiteral elements: (Int, Int)...) {
        fatalError("Support compiled out removed")
    }

    #else  // !REMOVE_LEGACY_NAMEMAP_INITIALIZERS

    /// Build the bidirectional maps between numbers and proto/JSON names.
    @available(
        *,
        deprecated,
        message: "Please regenerate your .pb.swift files with the current version of the SwiftProtobuf protoc plugin."
    )
    public init(
        reservedNames: [String],
        reservedRanges: [Range<Int32>],
        numberNameMappings: KeyValuePairs<Int, NameDescription>
    ) {
        self.reservedNames = reservedNames
        self.reservedRanges = reservedRanges

        initHelper(numberNameMappings)
    }

    /// Build the bidirectional maps between numbers and proto/JSON names.
    @available(
        *,
        deprecated,
        message: "Please regenerate your .pb.swift files with the current version of the SwiftProtobuf protoc plugin."
    )
    public init(dictionaryLiteral elements: (Int, NameDescription)...) {
        initHelper(elements)
    }

    /// Helper to share the building of mappings between the two initializers.
    private mutating func initHelper<Pairs: Collection>(
        _ elements: Pairs
    ) where Pairs.Element == (key: Int, value: NameDescription) {
        for (number, description) in elements {
            switch description {

            case .same(proto: let p):
                let protoName = Name(staticString: p, pool: internPool)
                let names = Names(json: protoName, proto: protoName)
                numberToNameMap[number] = names
                protoToNumberMap[protoName] = number
                jsonToNumberMap[protoName] = number

            case .standard(proto: let p):
                let protoName = Name(staticString: p, pool: internPool)
                let jsonString = toJSONFieldName(p)
                let jsonName = Name(string: jsonString, pool: internPool)
                let names = Names(json: jsonName, proto: protoName)
                numberToNameMap[number] = names
                protoToNumberMap[protoName] = number
                jsonToNumberMap[protoName] = number
                jsonToNumberMap[jsonName] = number

            case .unique(proto: let p, json: let j):
                let jsonName = Name(staticString: j, pool: internPool)
                let protoName = Name(staticString: p, pool: internPool)
                let names = Names(json: jsonName, proto: protoName)
                numberToNameMap[number] = names
                protoToNumberMap[protoName] = number
                jsonToNumberMap[protoName] = number
                jsonToNumberMap[jsonName] = number

            case .aliased(proto: let p, let aliases):
                let protoName = Name(staticString: p, pool: internPool)
                let names = Names(json: protoName, proto: protoName)
                numberToNameMap[number] = names
                protoToNumberMap[protoName] = number
                jsonToNumberMap[protoName] = number
                for alias in aliases {
                    let protoName = Name(staticString: alias, pool: internPool)
                    protoToNumberMap[protoName] = number
                    jsonToNumberMap[protoName] = number
                }
            }
        }
    }

    #endif  // !REMOVE_LEGACY_NAMEMAP_INITIALIZERS

    public init(bytecode: StaticString) {
        var previousNumber = 0
        BytecodeInterpreter<ProtoNameInstruction>(program: bytecode).execute { instruction, reader in
            func nextNumber() -> Int {
                let next: Int
                if instruction.hasExplicitDelta {
                    next = previousNumber + Int(reader.nextInt32())
                } else {
                    next = previousNumber + 1
                }
                previousNumber = next
                return next
            }

            switch instruction {
            case .sameNext, .sameDelta:
                let number = nextNumber()
                let protoName = Name(bytecodeUTF8Buffer: reader.nextNullTerminatedString())
                numberToNameMap[number] = Names(json: protoName, proto: protoName)
                protoToNumberMap[protoName] = number
                jsonToNumberMap[protoName] = number

            case .standardNext, .standardDelta:
                let number = nextNumber()
                let protoNameBuffer = reader.nextNullTerminatedString()
                let protoName = Name(bytecodeUTF8Buffer: protoNameBuffer)
                let jsonString = toJSONFieldName(protoNameBuffer)
                let jsonName = Name(string: jsonString, pool: internPool)
                numberToNameMap[number] = Names(json: jsonName, proto: protoName)
                protoToNumberMap[protoName] = number
                jsonToNumberMap[protoName] = number
                jsonToNumberMap[jsonName] = number

            case .uniqueNext, .uniqueDelta:
                let number = nextNumber()
                let protoName = Name(bytecodeUTF8Buffer: reader.nextNullTerminatedString())
                let jsonName = Name(bytecodeUTF8Buffer: reader.nextNullTerminatedString())
                numberToNameMap[number] = Names(json: jsonName, proto: protoName)
                protoToNumberMap[protoName] = number
                jsonToNumberMap[protoName] = number
                jsonToNumberMap[jsonName] = number

            case .groupNext, .groupDelta:
                let number = nextNumber()
                let protoNameBuffer = reader.nextNullTerminatedString()
                let protoName = Name(bytecodeUTF8Buffer: protoNameBuffer)
                protoToNumberMap[protoName] = number
                jsonToNumberMap[protoName] = number

                let lowercaseName: Name
                let hasUppercase = protoNameBuffer.contains { (UInt8(ascii: "A")...UInt8(ascii: "Z")).contains($0) }
                if hasUppercase {
                    lowercaseName = Name(
                        string: String(decoding: protoNameBuffer, as: UTF8.self).lowercased(),
                        pool: internPool
                    )
                    protoToNumberMap[lowercaseName] = number
                    jsonToNumberMap[lowercaseName] = number
                } else {
                    // No need to convert and intern a separate copy of the string
                    // if it would be identical.
                    lowercaseName = protoName
                }
                numberToNameMap[number] = Names(json: lowercaseName, proto: protoName)

            case .aliasNext, .aliasDelta:
                let number = nextNumber()
                let protoName = Name(bytecodeUTF8Buffer: reader.nextNullTerminatedString())
                numberToNameMap[number] = Names(json: protoName, proto: protoName)
                protoToNumberMap[protoName] = number
                jsonToNumberMap[protoName] = number
                for alias in reader.nextNullTerminatedStringArray() {
                    let protoName = Name(bytecodeUTF8Buffer: alias)
                    protoToNumberMap[protoName] = number
                    jsonToNumberMap[protoName] = number
                }

            case .reservedName:
                let name = String(decoding: reader.nextNullTerminatedString(), as: UTF8.self)
                reservedNames.append(name)

            case .reservedNumbers:
                let lowerBound = reader.nextInt32()
                let upperBound = lowerBound + reader.nextInt32()
                reservedRanges.append(lowerBound..<upperBound)
            }
        }
    }

    /// Returns the name bundle for the field/enum-case with the given number, or
    /// `nil` if there is no match.
    internal func names(for number: Int) -> Names? {
        numberToNameMap[number]
    }

    /// Returns the field/enum-case number that has the given JSON name,
    /// or `nil` if there is no match.
    ///
    /// This is used by the Text format parser to look up field or enum
    /// names using a direct reference to the un-decoded UTF8 bytes.
    internal func number(forProtoName raw: UnsafeRawBufferPointer) -> Int? {
        let n = Name(transientUtf8Buffer: raw)
        return protoToNumberMap[n]
    }

    /// Returns the field/enum-case number that has the given JSON name,
    /// or `nil` if there is no match.
    ///
    /// This accepts a regular `String` and is used in JSON parsing
    /// only when a field name or enum name was decoded from a string
    /// containing backslash escapes.
    ///
    /// JSON parsing must interpret *both* the JSON name of the
    /// field/enum-case provided by the descriptor *as well as* its
    /// original proto/text name.
    internal func number(forJSONName name: String) -> Int? {
        let utf8 = Array(name.utf8)
        return utf8.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            let n = Name(transientUtf8Buffer: buffer)
            return jsonToNumberMap[n]
        }
    }

    /// Returns the field/enum-case number that has the given JSON name,
    /// or `nil` if there is no match.
    ///
    /// This is used by the JSON parser when a field name or enum name
    /// required no special processing.  As a result, we can avoid
    /// copying the name and look up the number using a direct reference
    /// to the un-decoded UTF8 bytes.
    internal func number(forJSONName raw: UnsafeRawBufferPointer) -> Int? {
        let n = Name(transientUtf8Buffer: raw)
        return jsonToNumberMap[n]
    }

    /// Returns all proto names
    internal var names: [Name] {
        numberToNameMap.map(\.value.proto)
    }

    /// Returns if the given name was reserved.
    internal func isReserved(name: UnsafeRawBufferPointer) -> Bool {
        guard !reservedNames.isEmpty,
            let baseAddress = name.baseAddress,
            let s = utf8ToString(bytes: baseAddress, count: name.count)
        else {
            return false
        }
        return reservedNames.contains(s)
    }

    /// Returns if the given number was reserved.
    internal func isReserved(number: Int32) -> Bool {
        for range in reservedRanges {
            if range.contains(number) {
                return true
            }
        }
        return false
    }
}

// The `_NameMap` (and supporting types) are only mutated during their initial
// creation, then for the lifetime of the a process they are constant. Swift
// 5.10 flags the generated `_protobuf_nameMap` usages as a problem
// (https://github.com/apple/swift-protobuf/issues/1560) so this silences those
// warnings since the usage has been deemed safe.
//
// https://github.com/apple/swift-protobuf/issues/1561 is also opened to revisit
// the `_NameMap` generally as it dates back to the days before Swift perferred
// the UTF-8 internal encoding.
extension _NameMap: Sendable {}
extension _NameMap.Name: @unchecked Sendable {}
extension InternPool: @unchecked Sendable {}
