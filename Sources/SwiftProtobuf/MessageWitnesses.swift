// Sources/SwiftProtobuf/MessageWitnesses.swift - Concrete message runtime witnesses
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Operations performed by the runtime on messages without knowing their
/// concrete type at compile time.
///
// -----------------------------------------------------------------------------

/// The set of operations that the runtime requests generated code to perform on
/// messages without knowing their concrete type at compile time.
///
/// Since functions cannot be specialized directly in Swift, this enum acts as
/// a generic namespace for runtime support functions that operate on concrete
/// message types.
@_spi(ForGeneratedCodeOnly)
public enum MessageWitnesses<T: Message> {
    public static func perform(_ operation: MessageWitnessOperation) {
        switch operation {
        case .messageInitialize(let pointer, let result):
            let messagePointer = pointer.bindMemory(to: T.self, capacity: 1)
            messagePointer.initialize(to: T())
            result.pointee = Unmanaged.passUnretained(messagePointer.pointee.storageForRuntime)
        
        case .messageDeinitialize(let pointer):
            pointer.bindMemory(to: T.self, capacity: 1).deinitialize(count: 1)

        case .messageCopyInitialize(let source, let destination):
            destination.bindMemory(to: T.self, capacity: 1).initialize(
                to: source.bindMemory(to: T.self, capacity: 1).pointee)

        case .messageGetStorage(let pointer, let result):
            result.pointee = Unmanaged.passUnretained(
                pointer.bindMemory(to: T.self, capacity: 1).pointee.storageForRuntime)

        case .messageGetUniqueStorage(let pointer, let result):
            pointer.bindMemory(to: T.self, capacity: 1).pointee
                ._protobuf_ensureUniqueStorage(accessToken: MessageStorageToken())
            result.pointee = Unmanaged.passUnretained(
                pointer.bindMemory(to: T.self, capacity: 1).pointee.storageForRuntime)

        case .arrayInitialize(let pointer):
            pointer.bindMemory(to: [T].self, capacity: 1).initialize(to: [])
        
        case .arrayDeinitialize(let pointer):
            pointer.bindMemory(to: [T].self, capacity: 1).deinitialize(count: 1)

        case .arrayCopyInitialize(let source, let destination):
            destination.bindMemory(to: [T].self, capacity: 1).initialize(
                to: source.bindMemory(to: [T].self, capacity: 1).pointee)

        case .arrayGetCount(let pointer, let result):
            result.pointee = pointer.bindMemory(to: [T].self, capacity: 1).pointee.count

        case .arrayGetElementStorage(let pointer, let index, let result):
            result.pointee = Unmanaged.passUnretained(
                pointer.bindMemory(to: [T].self, capacity: 1).pointee[index].storageForRuntime)

        case .arrayAppendNew(let pointer, let result):
            let arrayPointer = pointer.bindMemory(to: [T].self, capacity: 1)
            arrayPointer.pointee.append(T())
            // Since this is a brand new element, it's guaranteed to have unique storage.
            result.pointee = Unmanaged.passUnretained(arrayPointer.pointee.last!.storageForRuntime)

        default:
            preconditionFailure("Unreachable")
        }
    }
}

/// The operations that the runtime requests from generated message types.
@_spi(ForGeneratedCodeOnly)
public enum MessageWitnessOperation {
    /// Initializes `pointer` to contain a new, empty instance of the concrete message type and populates
    /// `result` with an unretained reference to its storage.
    case messageInitialize(
        pointer: UnsafeMutableRawPointer,
        result: UnsafeMutablePointer<Unmanaged<MessageStorage>?>
    )

    /// Deinitializes a concrete message instance at `pointer`.
    case messageDeinitialize(pointer: UnsafeMutableRawPointer)

    /// Initializes `destination` as a copy of the message instance at `source`.
    ///
    /// The destination instance must be uninitialized when this is called.
    case messageCopyInitialize(source: UnsafeRawPointer, destination: UnsafeMutableRawPointer)

    /// Populates `result` with an unretained reference to the `MessageStorage` for the concrete message instance
    /// stored at `pointer`.
    case messageGetStorage(pointer: UnsafeRawPointer, result: UnsafeMutablePointer<Unmanaged<MessageStorage>?>)

    /// Ensures that the `MessageStorage` is unique for the concrete message instance stored at `pointer` and
    /// populates `result` with an unretained reference to the unique `MessageStorage`.
    case messageGetUniqueStorage(
        pointer: UnsafeMutableRawPointer,
        result: UnsafeMutablePointer<Unmanaged<MessageStorage>?>
    )

    /// Initializes `pointer` to contain a new, empty array of the concrete message type.
    case arrayInitialize(pointer: UnsafeMutableRawPointer)

    /// Deinitializes the array stored at `pointer`.
    case arrayDeinitialize(pointer: UnsafeMutableRawPointer)

    /// Initializes `destination` as a copy of the array at `source`.
    ///
    /// The destination array must be uninitialized when this is called.
    case arrayCopyInitialize(source: UnsafeRawPointer, destination: UnsafeMutableRawPointer)

    /// Populates `result` with the number of elements in the array stored at `pointer`.
    case arrayGetCount(pointer: UnsafeRawPointer, result: UnsafeMutablePointer<Int>)

    /// Populates `result` with an unretained reference to the `MessageStorage` for the message at `index` in
    /// the array stored at `pointer`.
    case arrayGetElementStorage(
        pointer: UnsafeRawPointer, index: Int, result: UnsafeMutablePointer<Unmanaged<MessageStorage>?>
    )

    /// Appends a new, default-initialized element to the array at `pointer` and populates `result` with
    /// an unretained reference to its storage.
    case arrayAppendNew(pointer: UnsafeMutableRawPointer, result: UnsafeMutablePointer<Unmanaged<MessageStorage>?>)

    /// Initializes `pointer` to contain a new, empty dictionary for a map field.
    case mapInitialize(pointer: UnsafeMutableRawPointer)

    /// Deinitializes the dictionary stored at `pointer`.
    case mapDeinitialize(pointer: UnsafeMutableRawPointer)

    /// Initializes `destination` as a copy of the map at `source`.
    ///
    /// The destination map must be uninitialized when this is called.
    case mapCopyInitialize(source: UnsafeMutableRawPointer, destination: UnsafeMutableRawPointer)

    /// Populates the given pointers with the size and alignment in bytes of the iterator for the dictionary that
    /// represents this map field.
    case mapGetIteratorSize(
        useDeterministicOrdering: Bool,
        size: UnsafeMutablePointer<Int>,
        alignment: UnsafeMutablePointer<Int>
    )

    /// Initializes the iterator for a map field at `pointer` into the memory pointed to by `iterator`.
    ///
    /// The memory pointed to by `iterator` must be uninitialized and of a size and alignment appropriate
    /// to hold the kind of iterator needed based on `useDeterministicOrdering`.
    case mapInitializeIterator(
        pointer: UnsafeMutableRawPointer,
        iterator: UnsafeMutableRawPointer,
        useDeterministicOrdering: Bool
    )

    /// Deinitializes the iterator.
    case mapDeinitializeIterator(iterator: UnsafeMutableRawPointer, useDeterministicOrdering: Bool)

    /// Populates the fields in `workingSpace` with the next element in the map and then advanced
    /// `iterator`.
    case mapNextElement(
        iterator: UnsafeMutableRawPointer,
        useDeterministicOrdering: Bool,
        workingSpace: MessageStorage,
        success: UnsafeMutablePointer<Bool>
    )

    /// Inserts the key and value from `workingSpace` into the dictionary located at `pointer`.
    case mapInsertElement(pointer: UnsafeMutableRawPointer, workingSpace: MessageStorage)

    /// Checks equality between two maps.
    ///
    /// Since map equality is order-independent, this would be more complex to implement in terms of
    /// the other iterator witnesses, so we just delegate to the underlying Swift `Dictionary`.
    case mapCheckEquality(lhs: UnsafeRawPointer, rhs: UnsafeRawPointer, result: UnsafeMutablePointer<Bool>)
}
