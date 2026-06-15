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
    /// +---------+--------------+----------------------------+
    /// | Bytes 0 | Bytes 1-13   | Bytes 14-variable          |
    /// | Version | Field schema | Length-prefixed field name |
    /// +---------+--------------+----------------------------+
    /// ```
    ///
    /// *   Byte 0: A `UInt8` that describes the version of the schema. Currently, this is always 0.
    ///     This value allows for future enhancements to be made to the schema but preserving backward
    ///     compatibility. **Important:** This must always match the version number of the message
    ///     schema used by the same generation.
    /// *   Bytes 1-13: The schema of the extension field. This is identical to the schema defined by
    ///     `MessageSchema.Field` for the message schema with the same version number.
    /// *   Bytes 14-variable: A 7-bit-encoded 2-byte integer indicating the length of the extension's
    ///     name followed by the UTF-8 blob that contains the name of the extension field.
    ///
    /// Note that even though extension fields use the same schema as regular fields, not all of the
    /// values are actually used. For example, presence is tracked differently and the byte offsets are
    /// always zero because extension fields are stored differently in memory that regular fields. This
    /// means that the schema string is slightly larger than it needs to be, but it is a worthwhile
    /// trade-off to let us reuse the same field schema code in the runtime and in the generator.
    private let schema: UnsafeRawBufferPointer

    @_spi(ForGeneratedCodeOnly)
    public typealias ExtendedMessageResolver = () -> MessageSchema

    @_spi(ForGeneratedCodeOnly)
    public typealias SubmessageOrEnumResolver = () -> SubmessageOrEnumSchema

    /// The function that is invoked to retrieve the schema of the message that this
    /// extension field extends.
    let extendedMessageResolver: ExtendedMessageResolver

    /// The function that is invoked to retrieve the schema for a submessage or enum field.
    let submessageOrEnumResolver: SubmessageOrEnumResolver

    /// The `MessageSchema` of the message that this extension field extends.
    package var extendedMessage: MessageSchema { extendedMessageResolver() }

    /// Creates a new extension schema for an extension field that is not a message or enum field.
    @_spi(ForGeneratedCodeOnly)
    public init(schema: StaticString, extendedMessageResolver: @escaping ExtendedMessageResolver) {
        self.init(
            schema: schema,
            extendedMessageResolver: extendedMessageResolver,
            submessageOrEnumResolver: {
                preconditionFailure("submessageOrEnumResolver called on non-message/group extension field")
            }
        )
    }

    /// Creates a new extension schema and submessage operations from the given values.
    @_spi(ForGeneratedCodeOnly)
    public init(
        schema: StaticString,
        extendedMessageResolver: @escaping ExtendedMessageResolver,
        submessageOrEnumResolver: @escaping SubmessageOrEnumResolver
    ) {
        precondition(
            schema.hasPointerRepresentation,
            "The schema string should have a pointer-based representation; this is a generator bug"
        )
        self.schema = UnsafeRawBufferPointer(start: schema.utf8Start, count: schema.utf8CodeUnitCount)
        self.extendedMessageResolver = extendedMessageResolver
        self.submessageOrEnumResolver = submessageOrEnumResolver
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
    @usableFromInline var field: MessageSchema.Field {
        MessageSchema.Field(slice: schema[1..<(1 + fieldSchemaSize)])
    }

    /// The field number of the extension field.
    package var fieldNumber: UInt32 {
        field.fieldNumber
    }

    /// The name of the extension field.
    var fieldName: UTF8Name {
        let lengthOffset = 1 + fieldSchemaSize
        let length = fixed2ByteBase128(in: schema, atByteOffset: lengthOffset)
        let nameStart = lengthOffset + 2
        return UTF8Name(start: schema.baseAddress! + nameStart, count: length)
    }

    /// The message schema for this extension field, if it is a message or group.
    ///
    /// - Precondition: The extension field must be a message or group field.
    var messageSchema: MessageSchema {
        guard case .message(let messageSchema) = submessageOrEnumResolver() else {
            fatalError("messageSchema called on non-message/group extension field")
        }
        return messageSchema
    }

    /// The enum schema for this extension field, if it is an enum.
    ///
    /// - Precondition: The extension field must be an enum field.
    var enumSchema: EnumSchema {
        guard case .enum(let enumSchema) = submessageOrEnumResolver() else {
            fatalError("enumSchema called on non-enum extension field")
        }
        return enumSchema
    }
}
