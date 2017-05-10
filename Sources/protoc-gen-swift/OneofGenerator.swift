// Sources/protoc-gen-swift/OneofGenerator.swift - Oneof handling
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This class represents a single Oneof in the proto and generates an efficient
/// algebraic enum to store it in memory.
///
// -----------------------------------------------------------------------------
import Foundation
import PluginLibrary
import SwiftProtobuf

extension Google_Protobuf_OneofDescriptorProto {
    var swiftFieldName: String {
        return toLowerCamelCase(name)
    }
    var swiftStorageFieldName: String {
        return "_" + toLowerCamelCase(name)
    }
    var swiftRelativeType: String {
        return "OneOf_" + toUpperCamelCase(name)
    }
}

class OneofGenerator {
    private let oneofDescriptor: OneofDescriptor
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer
    private let usesHeapStorage: Bool

    private let fields: [MessageFieldGenerator]
    private let fieldsSortedByNumber: [MessageFieldGenerator]
    private let oneofIsContinuousInParent: Bool
    private let swiftRelativeName: String
    private let swiftFullName: String
    private let comments: String

    private var descriptor: Google_Protobuf_OneofDescriptorProto { return oneofDescriptor.proto }

    /// Returns a Swift pattern (or list of patterns) suitable for a `case`
    /// statement that matches any of the field numbers corresponding to the
    /// `oneof` with the given index.
    ///
    /// This function collapses large contiguous field number sequences into
    /// into range patterns instead of listing all of the fields explicitly.
    ///
    /// - Parameter index: The index of the `oneof`.
    /// - Returns: The Swift pattern(s) that match the `oneof`'s field numbers.
    private var fieldNumbersPattern: String {
        let fieldNumbers = fieldsSortedByNumber.map { $0.number }
        assert(fieldNumbers.count > 0)

        if fieldNumbers.count <= 2 {
            // For one or two fields, just return "n" or "n, m". ("n...m" would
            // also be valid, but this is one character shorter.)
            return fieldNumbers.lazy.map { String($0) }.joined(separator: ", ")
        }

        let first = fieldNumbers.first!
        let last = fieldNumbers.last!

        if first + fieldNumbers.count - 1 == last {
            // The field numbers were contiguous, so return a range instead.
            return "\(first)...\(last)"
        }
        // Not a contiguous range, so just print the comma-delimited list of
        // field numbers. (We could consider optimizing this to print ranges
        // for contiguous subsequences later, as well.)
        return fieldNumbers.lazy.map { String($0) }.joined(separator: ", ")
    }

    init(descriptor: OneofDescriptor, generatorOptions: GeneratorOptions, namer: SwiftProtobufNamer, fields: [MessageFieldGenerator], usesHeapStorage: Bool) {
        self.oneofDescriptor = descriptor
        self.generatorOptions = generatorOptions
        self.namer = namer
        self.usesHeapStorage = usesHeapStorage

        self.fields = fields
        self.fieldsSortedByNumber = fields.sorted {$0.number < $1.number}
        self.comments = descriptor.protoSourceComments()

        swiftRelativeName = namer.relativeName(oneof: descriptor)
        swiftFullName = namer.fullName(oneof: descriptor)

        let first = fieldsSortedByNumber.first!.number
        let last = fieldsSortedByNumber.last!.number
        // Easy case, all in order and no gaps:
        if first + fields.count - 1 == last {
            oneofIsContinuousInParent = true
        } else {
            // See if all the oneof fields were in order within the (even if there were number gaps).
            //    message Good {
            //      oneof o {
            //        int32 a = 1;
            //        int32 z = 26;
            //      }
            //    }
            //    message Bad {
            //      oneof o {
            //        int32 a = 1;
            //        int32 z = 26;
            //      }
            //      int32 m = 13;
            //    }
            let sortedOneofFieldNumbers = fieldsSortedByNumber.map { $0.number }
            let parentFieldNumbersSorted = descriptor.containingType.fields.map({ Int($0.number) }).sorted { $0 < $1 }
            let firstIndex = parentFieldNumbersSorted.index(of: first)!
            var isContinuousInParent = sortedOneofFieldNumbers == Array(parentFieldNumbersSorted[firstIndex..<(firstIndex + fields.count)])
            if isContinuousInParent {
                // Make sure there isn't an extension range in the middle of the fields.
                //    message AlsoBad {
                //      oneof o {
                //        int32 a = 1;
                //        int32 z = 26;
                //      }
                //      extensions 10 to 16;
                //    }
                for e in descriptor.containingType.extensionRanges {
                    if e.start > Int32(first) && e.end <= Int32(last) {
                        isContinuousInParent = false
                        break
                    }
                }
            }
            oneofIsContinuousInParent = isContinuousInParent
        }
    }

    func generateMainEnum(printer p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet

        // Repeat the comment from the oneof to provide some context
        // to this enum we generated.
        p.print(
            "\n",
            comments,
            "\(visibility)enum \(swiftRelativeName): Equatable {\n")
        p.indent()

        // Oneof case for each ivar
        for f in fields {
            p.print(
                f.comments,
                "case \(f.swiftName)(\(f.swiftBaseType))\n")
        }

        // Equatable conformance
        p.print(
            "\n",
            "\(visibility)static func ==(lhs: \(swiftFullName), rhs: \(swiftFullName)) -> Bool {\n")
        p.indent()
        p.print("switch (lhs, rhs) {\n")
        for f in fields {
            p.print("case (.\(f.swiftName)(let l), .\(f.swiftName)(let r)): return l == r\n")
        }
        if fields.count > 1 {
            // A tricky edge case: If the oneof only has a single case, then
            // the case pattern generated above is exhaustive and generating a
            // default produces a compiler error. If there is more than one
            // case, then the case patterns are not exhaustive (because we
            // don't compare mismatched pairs), and we have to include a
            // default.
            p.print("default: return false\n")
        }
        p.print("}\n")
        p.outdent()
        p.print("}\n")

        p.outdent()
        p.print("}\n")
    }

    func generateRuntimeSupport(printer p: inout CodePrinter) {
        let isProto3 = oneofDescriptor.containingType.file.syntax == .proto3

        p.print(
            "\n",
            "extension \(swiftFullName) {\n")
        p.indent()

        // Decode one of our members
        p.print("fileprivate init?<T: SwiftProtobuf.Decoder>(byDecodingFrom decoder: inout T, fieldNumber: Int) throws {\n")
        p.indent()
        p.print("switch fieldNumber {\n")
        for f in fieldsSortedByNumber {
            let modifier = "Singular"
            let special = f.isGroup ? "Group"
                        : f.isMessage ? "Message"
                        : f.isEnum ? "Enum"
                        : f.protoTypeName
            let decoderMethod = "decode\(modifier)\(special)Field"

            p.print("case \(f.number):\n")
            p.indent()
            if isProto3 && !f.isMessage && !f.isGroup {
                // Proto3 has non-optional fields, so this is simpler
                p.print(
                    "var value = \(f.swiftStorageType)()\n",
                    "try decoder.\(decoderMethod)(value: &value)\n",
                    "self = .\(f.swiftName)(value)\n",
                    "return\n")
            } else {
                p.print(
                    "var value: \(f.swiftStorageType)\n",
                    "try decoder.\(decoderMethod)(value: &value)\n",
                    "if let value = value {\n")
                p.indent()
                p.print(
                    "self = .\(f.swiftName)(value)\n",
                    "return\n")
                p.outdent()
                p.print("}\n")
            }
            p.outdent()
        }
        p.print("default:\n")
        p.indent()
        p.print("break\n")
        p.outdent()
        p.print(
            "}\n",
            "return nil\n")
        p.outdent()
        p.print("}\n")

        // Traverse the current value
        p.print("\n")
        if oneofIsContinuousInParent {
            p.print("fileprivate func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {\n")
        } else {
            p.print("fileprivate func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V, start: Int, end: Int) throws {\n")
        }
        p.indent()
        p.print("switch self {\n")
        for f in fieldsSortedByNumber {
            p.print("case .\(f.swiftName)(let v):\n")
            p.indent()
            if !oneofIsContinuousInParent {
                p.print("if start <= \(f.number) && \(f.number) < end {\n")
                p.indent()
            }
            let special = f.isGroup ? "Group" : f.isMessage ? "Message" : f.isEnum ? "Enum" : f.protoTypeName;
            let visitorMethod = "visitSingular\(special)Field"
            p.print("try visitor.\(visitorMethod)(value: v, fieldNumber: \(f.number))\n")
            if !oneofIsContinuousInParent {
                p.outdent()
                p.print("}\n")
            }
            p.outdent()
        }
        p.print("}\n")
        p.outdent()
        p.print("}\n")

        p.outdent()
        p.print("}\n")
    }

    func generateProxyIvar(printer p: inout CodePrinter) {
        p.print(
            "\n",
            comments,
            "\(generatorOptions.visibilitySourceSnippet)var \(descriptor.swiftFieldName): \(swiftRelativeName)? {\n")
        p.indent()
        p.print(
            "get {return _storage.\(descriptor.swiftStorageFieldName)}\n",
            "set {_uniqueStorage().\(descriptor.swiftStorageFieldName) = newValue}\n")
        p.outdent()
        p.print("}\n")
    }

    func generateTopIvar(printer p: inout CodePrinter) {
        p.print(
            "\n",
            comments,
            "\(generatorOptions.visibilitySourceSnippet)var \(descriptor.swiftFieldName): \(swiftFullName)? = nil\n")
    }

    func generateStorageIvar(printer p: inout CodePrinter) {
        p.print(
            "var \(descriptor.swiftStorageFieldName): \(swiftFullName)?\n")
    }

    private func storedProperty(in variable: String = "") -> String {
        if usesHeapStorage {
            return "\(variable)_storage._\(descriptor.swiftFieldName)"
        }
        let prefix = variable.isEmpty ? "self." : "\(variable)."
        return "\(prefix)\(descriptor.swiftFieldName)"
    }

    func generateDecodeMessage(printer p: inout CodePrinter) {
        p.print("case \(fieldNumbersPattern):\n")
        p.indent()
        p.print("if \(storedProperty()) != nil {\n")
        p.indent()
        p.print("try decoder.handleConflictingOneOf()\n")
        p.outdent()
        p.print("}\n")
        p.print("\(storedProperty()) = try \(swiftFullName)(byDecodingFrom: &decoder, fieldNumber: fieldNumber)\n")
        p.outdent()
    }

    func generateMessageTraverse(printer p: inout CodePrinter, start: Int, end: Int) {
        if oneofIsContinuousInParent {
            p.print("try \(storedProperty())?.traverse(visitor: &visitor)\n")
        } else {
            p.print("try \(storedProperty())?.traverse(visitor: &visitor, start: \(start), end: \(end))\n")
        }
    }

    func inequalityComprison(_ otherVar: String) -> String {
        return "\(storedProperty()) != \(storedProperty(in: otherVar))"
    }

    func generateStorageClone(printer p: inout CodePrinter) {
        p.print("\(descriptor.swiftStorageFieldName) = source.\(descriptor.swiftStorageFieldName)\n")
    }

    func generateIsInitializedCheck(printer p: inout CodePrinter) {
        let fieldsToCheck = fields.filter {
            $0.isGroupOrMessage && $0.messageType.hasRequiredFields()
        }
        if fieldsToCheck.count == 1 {
            let f = fieldsToCheck.first!
            p.print("if case .\(f.swiftName)(let v)? = \(storedProperty()), !v.isInitialized {return false}\n")
        } else if fieldsToCheck.count > 1 {
            p.print("switch \(storedProperty()) {\n")
            for f in fieldsToCheck {
                p.print("case .\(f.swiftName)(let v)?: if !v.isInitialized {return false}\n")
            }
            // Covers other cases or if the oneof wasn't set (was nil).
            p.print(
              "default: break\n",
              "}\n")
        }
    }

}
