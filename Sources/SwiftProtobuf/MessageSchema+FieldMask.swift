// Sources/SwiftProtobuf/MessageSchema+FieldMask.swift - Field mask extensions for schemas
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `MessageSchema` to support field masks.
///
// -----------------------------------------------------------------------------

#if FieldMaskUtilities

extension MessageSchema {
    /// Checks if a dot-separated path is valid for this message schema.
    func isPathValid(_ path: String) -> Bool {
        let components = path.split(separator: ".")
        guard !components.isEmpty else { return false }
        var currentSchema = self

        for (i, component) in components.enumerated() {
            guard let fieldNumber = currentSchema.fieldNumber(forTextName: String(component)) else {
                return false
            }

            if i == components.count - 1 {
                // This was the last component and it was found.
                return true
            }

            // If it's not the last component, it must be a message or group.
            guard
                let field = currentSchema[fieldNumber: fieldNumber],
                field.rawFieldType == .message || field.rawFieldType == .group
            else {
                return false
            }
            let token = SubmessageOrEnumToken(index: field.submessageIndex)
            guard case .message(let nextSchema) = currentSchema.submessageOrEnumResolver(token) else {
                return false
            }

            currentSchema = nextSchema
        }

        return false
    }
}

#endif
