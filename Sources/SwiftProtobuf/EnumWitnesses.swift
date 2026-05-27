// Sources/SwiftProtobuf/EnumWitnesses.swift - Concrete enum runtime witnesses
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Operations performed by the runtime on enums without knowing their concrete
/// type at compile time.
///
// -----------------------------------------------------------------------------

/// The set of operations that the runtime requests generated code to perform on
/// enums without knowing their concrete type at compile time.
///
/// Since functions cannot be specialized directly in Swift, this enum acts as
/// a generic namespace for runtime support functions that operate on concrete
/// enum types.
@_spi(ForGeneratedCodeOnly)
public enum EnumWitnesses<T: Enum> {
    public static func perform(_ operation: EnumWitnessOperation) {
        switch operation {
        case .rawValueIsValid(let rawValue, let result):
            result.pointee = T(rawValue: Int(rawValue)) != nil

        case .arrayInitialize(let pointer):
            pointer.bindMemory(to: [T].self, capacity: 1).initialize(to: [])

        case .arrayDeinitialize(let pointer):
            pointer.bindMemory(to: [T].self, capacity: 1).deinitialize(count: 1)

        case .arrayCopyInitialize(let source, let destination):
            destination.bindMemory(to: [T].self, capacity: 1).initialize(
                to: source.bindMemory(to: [T].self, capacity: 1).pointee
            )

        case .arrayGetCount(let pointer, let result):
            result.pointee = pointer.bindMemory(to: [T].self, capacity: 1).pointee.count

        case .arrayGetElementRawValue(let pointer, let index, let result):
            result.pointee = Int32(pointer.bindMemory(to: [T].self, capacity: 1).pointee[index].rawValue)

        case .arrayAppendRawValue(let pointer, let rawValue):
            // The validity of the raw value has already been checked by the caller.
            let value = T(rawValue: Int(rawValue))!
            pointer.bindMemory(to: [T].self, capacity: 1).pointee.append(value)
        }
    }
}

/// The operations that the runtime requests from generated enum types.
@_spi(ForGeneratedCodeOnly)
public enum EnumWitnessOperation {
    /// Checks if the given raw value is valid for the enum type and populates `result` with the result.
    ///
    /// TODO: This is only necessary right now because the only way we have to check that a raw value
    /// is valid for a protobuf enum is to initialize the Swift type and see if it succeeds. We should
    /// consider adopting something like upb's sparse representation to check validity without this
    /// round trip.
    case rawValueIsValid(rawValue: Int32, result: UnsafeMutablePointer<Bool>)

    /// Initializes `pointer` to contain an empty array of the concrete enum type.
    case arrayInitialize(pointer: UnsafeMutableRawPointer)

    /// Deinitializes an array of a repeated enum type located at `pointer`.
    case arrayDeinitialize(pointer: UnsafeMutableRawPointer)

    /// Initializes `destination` as a copy of the array at `source`.
    ///
    /// The destination array must be uninitialized when this is called.
    case arrayCopyInitialize(source: UnsafeRawPointer, destination: UnsafeMutableRawPointer)

    /// Populates `result` with the number of elements in the array located at `pointer`.
    case arrayGetCount(pointer: UnsafeRawPointer, result: UnsafeMutablePointer<Int>)

    /// Populates `result` with the raw value for the enum at `index` in the array located at `pointer`.
    case arrayGetElementRawValue(pointer: UnsafeRawPointer, index: Int, result: UnsafeMutablePointer<Int32>)

    /// Appends an enum value (by its raw value) to the array located at `pointer`.
    case arrayAppendRawValue(pointer: UnsafeMutableRawPointer, rawValue: Int32)
}
