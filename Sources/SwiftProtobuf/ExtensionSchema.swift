// Sources/SwiftProtobuf/ExtensionSchema.swift - Extension support
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Describes the schema of a particular extension field.
///
// -----------------------------------------------------------------------------

/// Describes a single extension field with enough detail for it to be modified in memory and to be
/// serialized and parsed.
public struct ExtensionSchema: @unchecked Sendable {
    // Using `UnsafeRawBufferPointer` requires that we declare the `Sendable` conformance as
    // `@unchecked`. Clearly this is safe because the pointer obtained from a `StaticString` is an
    // immortal compile-time constant and we only read from it.

    /// The encoded schema of the extension field.
    ///
    /// ## Encoded Schema
    ///
    /// Like the message schema, the extension schema is encoded in UTF-8-compatible form as a
    /// `StaticString`:
    ///
    /// ```
    /// +---------+--------------+-------------------+
    /// | Bytes 0 | Bytes 1-13   | Bytes 14-variable |
    /// | Version | Field schema | Field name        |
    /// +---------+--------------+-------------------+
    /// ```
    ///
    /// *   Byte 0: A `UInt8` that describes the version of the schema. Currently, this is always 0.
    ///     This value allows for future enhancements to be made to the schema but preserving backward
    ///     compatibility. **Important:** This must always match the version number of the message
    ///     schema used by the same generation.
    /// *   Bytes 1-13: The schema of the extension field. This is identical to the schema defined by
    ///     `FieldSchema` for the message schema with the same version number.
    /// *   Bytes 14-variable: A variable-length UTF-8 blob that contains the name of the extension
    ///     field.
    ///
    /// Note that even though extension fields use the same schema as regular fields, not all of the
    /// values are actually used. For example, presence is tracked differently and the byte offsets are
    /// always zero because extension fields are stored differently in memory that regular fields. This
    /// means that the schema string is slightly larger than it needs to be, but it is a worthwhile
    /// trade-off to let us reuse the same field schema code in the runtime and in the generator.
    private let schema: UnsafeRawBufferPointer

    /// The function type for the generated function that is called to perform a basic operation
    /// on certain kinds of nontrivial fields (a message, array of messages, array of enums, or map)
    /// such as deinitialization, copying, or testing for equality.
    @_spi(ForGeneratedCodeOnly)
    public typealias NontrivialExtensionOperationPerformer = (
        _ operation: NontrivialExtensionOperation,
        _ ext: ExtensionSchema,
        _ storage: ExtensionStorage
    ) -> Bool

    /// The function type for the generated function that is called to perform an arbitrary
    /// operation on the storage of a field whose type is a message or array of messages.
    @_spi(ForGeneratedCodeOnly)
    public typealias SubmessageStoragePerformer = (
        _ ext: ExtensionSchema,
        _ storage: ExtensionStorage,
        _ operation: TrampolineFieldOperation,
        _ perform: (_MessageStorage) throws -> Bool
    ) throws -> Bool

    /// The function type for the generated function that is called to perform an arbitrary
    /// operation on the raw values of a singular or repeated enum field.
    @_spi(ForGeneratedCodeOnly)
    public typealias RawEnumValuesPerformer = (
        _ ext: ExtensionSchema,
        _ storage: ExtensionStorage,
        _ operation: TrampolineFieldOperation,
        _ perform: (EnumSchema, inout Int32) throws -> Bool,
        _ onInvalidValue: (Int32) throws -> Void
    ) throws -> Void

    /// The function that is called to deinitialize, copy, or test equality of a field whose type
    /// is a message (singular or repeated) or a repeated enum field.
    let performNontrivialExtensionOperation: NontrivialExtensionOperationPerformer

    /// The function that is called to perform an arbitrary operation on the storage of a submessage
    /// field.
    let performOnSubmessageStorage: SubmessageStoragePerformer

    /// The function that is called to perform an arbitrary operation on the raw values of an enum
    /// field.
    let performOnRawEnumValues: RawEnumValuesPerformer

    /// Creates a new extension schema and submessage operations from the given values.
    private init(
        schema: StaticString,
        performNontrivialExtensionOperation: @escaping NontrivialExtensionOperationPerformer,
        performOnSubmessageStorage: @escaping SubmessageStoragePerformer,
        performOnRawEnumValues: @escaping RawEnumValuesPerformer
    ) {
        precondition(
            schema.hasPointerRepresentation,
            "The schema string should have a pointer-based representation; this is a generator bug"
        )
        self.schema = UnsafeRawBufferPointer(start: schema.utf8Start, count: schema.utf8CodeUnitCount)
        self.performNontrivialExtensionOperation = performNontrivialExtensionOperation
        self.performOnSubmessageStorage = performOnSubmessageStorage
        self.performOnRawEnumValues = performOnRawEnumValues
        precondition(version == 0, "This runtime only supports version 0 message schemas")
    }

    @_spi(ForGeneratedCodeOnly)
    public init(schema: StaticString) {
        self.init(
            schema: schema,
            performNontrivialExtensionOperation: { _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnSubmessageStorage: { _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnRawEnumValues: { _, _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            }
        )
    }

    @_spi(ForGeneratedCodeOnly)
    public init(
        schema: StaticString,
        performNontrivialExtensionOperation: @escaping NontrivialExtensionOperationPerformer
    ) {
        self.init(
            schema: schema,
            performNontrivialExtensionOperation: performNontrivialExtensionOperation,
            performOnSubmessageStorage: { _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnRawEnumValues: { _, _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            }
        )
    }

    @_spi(ForGeneratedCodeOnly)
    public init(
        schema: StaticString,
        performNontrivialExtensionOperation: @escaping NontrivialExtensionOperationPerformer,
        performOnSubmessageStorage: @escaping SubmessageStoragePerformer
    ) {
        self.init(
            schema: schema,
            performNontrivialExtensionOperation: performNontrivialExtensionOperation,
            performOnSubmessageStorage: performOnSubmessageStorage,
            performOnRawEnumValues: { _, _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            }
        )
    }

    @_spi(ForGeneratedCodeOnly)
    public init(
        schema: StaticString,
        performNontrivialExtensionOperation: @escaping NontrivialExtensionOperationPerformer,
        performOnRawEnumValues: @escaping RawEnumValuesPerformer
    ) {
        self.init(
            schema: schema,
            performNontrivialExtensionOperation: performNontrivialExtensionOperation,
            performOnSubmessageStorage: { _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnRawEnumValues: performOnRawEnumValues
        )
    }
}

/// The size, in bytes, of the header the describes the overall extension schema.
private var extensionSchemaHeaderSize: Int { 1 }

extension ExtensionSchema {
    /// The version of the schema data.
    ///
    /// Currently, the runtime only supports version 0. If the schema needs to change in a breaking
    /// way, the generator should increment the version and the runtime implementation should detect
    /// the new version while maintaining the ability to read the older schemas.
    private var version: UInt8 {
        schema.load(fromByteOffset: 0, as: UInt8.self)
    }

    /// The schema of the extension field.
    @_spi(ForGeneratedCodeOnly)
    @usableFromInline var field: FieldSchema {
        FieldSchema(slice: schema[1..<(1 + fieldSchemaSize)])
    }

    var fieldName: String {
        // TODO: Once we've trimmed out the legacy code that will no longer be used, consider
        // exposing this slice directly and letting encoders/decoders work with it so that we
        // avoid having to materialize a new string every time.
        String(decoding: schema[(1 + fieldSchemaSize)...], as: UTF8.self)
    }
}
