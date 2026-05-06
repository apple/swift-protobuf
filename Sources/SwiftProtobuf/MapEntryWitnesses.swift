// Sources/SwiftProtobuf/MapEntryWitnesses.swift - Concrete map entry runtime witnesses
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Operations performed by the runtime on map entries without knowing their
/// concrete key and value types at compile time.
///
// -----------------------------------------------------------------------------

/// The set of operations that the runtime requests generated code to perform on
/// map entries without knowing their concrete key and value types at compile
/// time.
///
/// Since functions cannot be specialized directly in Swift, this enum acts as
/// a generic namespace for runtime support functions that operate on concrete
/// dictionary types.
@_spi(ForGeneratedCodeOnly)
public enum MapEntryWitnesses<K: ProtobufMapKey, V: ProtobufMapParticipant> {
    public static func perform(_ operation: MessageWitnessOperation) {
        typealias DictType = [K.Base: V.Base]
        typealias StandardIteratorType = DictType.Iterator
        typealias DeterministicIteratorType = Array<DictType.Element>.Iterator

        switch operation {
        case .mapInitialize(let pointer):
            pointer.bindMemory(to: DictType.self, capacity: 1).initialize(to: [:])
        
        case .mapDeinitialize(let pointer):
            pointer.bindMemory(to: DictType.self, capacity: 1).deinitialize(count: 1)

        case .mapCopyInitialize(let source, let destination):
            destination.bindMemory(to: DictType.self, capacity: 1).initialize(
                to: source.bindMemory(to: DictType.self, capacity: 1).pointee)

        case .mapGetIteratorSize(let isDeterministicOrder, let size, let alignment):
            size.pointee = isDeterministicOrder
                ? MemoryLayout<DeterministicIteratorType>.size
                : MemoryLayout<StandardIteratorType>.size
            alignment.pointee = isDeterministicOrder
                ? MemoryLayout<DeterministicIteratorType>.alignment
                : MemoryLayout<StandardIteratorType>.alignment

        case .mapInitializeIterator(let pointer, let iterator, let useDeterministicOrdering):
            let dictionaryPointer = pointer.bindMemory(to: DictType.self, capacity: 1)
            if useDeterministicOrdering {
                // Copy the elements into a new array, sorted by key.
                let sortedElements = dictionaryPointer.pointee.sorted {
                    K.keyLessThan(lhs: $0.0, rhs: $1.0)
                }
                // `sortedElements` is a local `Array`. It's safe to let this iterator escape here
                // because Swift iterators hold onto references to their underlying collection. This
                // lets us treat the iterator as the sole view into the elements, which is what we
                // want for the duration of the iteration.
                iterator.initializeMemory(as: DeterministicIteratorType.self, to: sortedElements.makeIterator())
            } else {
                iterator.initializeMemory(as: StandardIteratorType.self, to: dictionaryPointer.pointee.makeIterator())
            }

        case .mapDeinitializeIterator(let iterator, let useDeterministicOrdering):
            if useDeterministicOrdering {
                iterator.bindMemory(to: DeterministicIteratorType.self, capacity: 1).deinitialize(count: 1)
            } else {
                iterator.bindMemory(to: StandardIteratorType.self, capacity: 1).deinitialize(count: 1)
            }

        case .mapNextElement(let iterator, let useDeterministicOrdering, let workingSpace, let success):
            let keyField = KnownField.mapEntryKey(in: workingSpace.schema)
            let valueField = KnownField.mapEntryValue(in: workingSpace.schema)
            guard
                case .hasBit(let keyHasByteOffset, let keyHasBitMask) = keyField.presence,
                case .hasBit(let valueHasByteOffset, let valueHasBitMask) = valueField.presence
            else {
                preconditionFailure("unreachable")
            }
            let keyHasBit = (keyHasByteOffset, keyHasBitMask)
            let valueHasBit = (valueHasByteOffset, valueHasBitMask)

            if useDeterministicOrdering {
                if let (key, value) = iterator.bindMemory(to: DeterministicIteratorType.self, capacity: 1).pointee.next() {
                    K.updateValue(at: keyField.offset, in: workingSpace, to: key, hasBit: keyHasBit)
                    V.updateValue(at: valueField.offset, in: workingSpace, to: value, hasBit: valueHasBit)
                    success.pointee = true
                    return
                }
                success.pointee = false
                return
            }

            if let (key, value) = iterator.bindMemory(to: StandardIteratorType.self, capacity: 1).pointee.next() {
                K.updateValue(at: keyField.offset, in: workingSpace, to: key, hasBit: keyHasBit)
                V.updateValue(at: valueField.offset, in: workingSpace, to: value, hasBit: valueHasBit)
                success.pointee = true
                return
            }
            success.pointee = false

        case .mapInsertElement(let pointer, let workingSpace):
            let keyField = KnownField.mapEntryKey(in: workingSpace.schema)
            let valueField = KnownField.mapEntryValue(in: workingSpace.schema)
            guard
                case .hasBit(let keyHasByteOffset, let keyHasBitMask) = keyField.presence,
                case .hasBit(let valueHasByteOffset, let valueHasBitMask) = valueField.presence
            else {
                preconditionFailure("unreachable")
            }
            let keyHasBit = (keyHasByteOffset, keyHasBitMask)
            let valueHasBit = (valueHasByteOffset, valueHasBitMask)

            let dictionaryPointer = pointer.bindMemory(to: DictType.self, capacity: 1)
            let key = K.value(at: keyField.offset, in: workingSpace, hasBit: keyHasBit)
            let value = V.value(at: valueField.offset, in: workingSpace, hasBit: valueHasBit)
            dictionaryPointer.pointee[key] = value

        case .mapCheckEquality(let lhs, let rhs, let result):
            result.pointee =
                lhs.bindMemory(to: DictType.self, capacity: 1).pointee
                == rhs.bindMemory(to: DictType.self, capacity: 1).pointee

        default:
            preconditionFailure("Unreachable")
        }
    }
}
