// Tests/protoc-gen-swiftTests/Test_DescriptorExtensions.swift - Test Descriptor+Extensions.swift
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import XCTest
import SwiftProtobuf
import SwiftProtobufPluginLibrary
@testable import protoc_gen_swift

fileprivate typealias FileDescriptorProto = Google_Protobuf_FileDescriptorProto

final class Test_DescriptorExtensions: XCTestCase {

  func testExtensionRanges() throws {
    let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)

    let descriptorSet = DescriptorSet(proto: fileSet)

    let msgDescriptor = descriptorSet.descriptor(named: "swift_descriptor_test.MsgExtensionRangeOrdering")!
    // Quick check of what should be in the proto file
    XCTAssertEqual(msgDescriptor.messageExtensionRanges.count, 9)
    XCTAssertEqual(msgDescriptor.messageExtensionRanges[0].start, 1)
    XCTAssertEqual(msgDescriptor.messageExtensionRanges[1].start, 3)
    XCTAssertEqual(msgDescriptor.messageExtensionRanges[2].start, 2)
    XCTAssertEqual(msgDescriptor.messageExtensionRanges[3].start, 4)
    XCTAssertEqual(msgDescriptor.messageExtensionRanges[4].start, 7)
    XCTAssertEqual(msgDescriptor.messageExtensionRanges[5].start, 9)
    XCTAssertEqual(msgDescriptor.messageExtensionRanges[6].start, 100)
    XCTAssertEqual(msgDescriptor.messageExtensionRanges[7].start, 126)
    XCTAssertEqual(msgDescriptor.messageExtensionRanges[8].start, 111)

    // Check sorting/merging
    XCTAssertEqual(msgDescriptor._normalizedExtensionRanges.count, 5)
    XCTAssertEqual(msgDescriptor._normalizedExtensionRanges[0].lowerBound, 1)
    XCTAssertEqual(msgDescriptor._normalizedExtensionRanges[0].upperBound, 5)
    XCTAssertEqual(msgDescriptor._normalizedExtensionRanges[1].lowerBound, 7)
    XCTAssertEqual(msgDescriptor._normalizedExtensionRanges[1].upperBound, 8)
    XCTAssertEqual(msgDescriptor._normalizedExtensionRanges[2].lowerBound, 9)
    XCTAssertEqual(msgDescriptor._normalizedExtensionRanges[2].upperBound, 10)
    XCTAssertEqual(msgDescriptor._normalizedExtensionRanges[3].lowerBound, 100)
    XCTAssertEqual(msgDescriptor._normalizedExtensionRanges[3].upperBound, 121)
    XCTAssertEqual(msgDescriptor._normalizedExtensionRanges[4].lowerBound, 126)
    XCTAssertEqual(msgDescriptor._normalizedExtensionRanges[4].upperBound, 131)


    // Check the "ambitious" merging.
    XCTAssertEqual(msgDescriptor._ambitiousExtensionRanges.count, 1)
    XCTAssertEqual(msgDescriptor._ambitiousExtensionRanges[0].lowerBound, 1)
    XCTAssertEqual(msgDescriptor._ambitiousExtensionRanges[0].upperBound, 131)

    let msgDescriptor2 = descriptorSet.descriptor(named: "swift_descriptor_test.MsgExtensionRangeOrderingWithFields")!
    // Quick check of what should be in the proto file
    XCTAssertEqual(msgDescriptor2.messageExtensionRanges.count, 9)
    XCTAssertEqual(msgDescriptor2.messageExtensionRanges[0].start, 1)
    XCTAssertEqual(msgDescriptor2.messageExtensionRanges[1].start, 3)
    XCTAssertEqual(msgDescriptor2.messageExtensionRanges[2].start, 2)
    XCTAssertEqual(msgDescriptor2.messageExtensionRanges[3].start, 4)
    XCTAssertEqual(msgDescriptor2.messageExtensionRanges[4].start, 7)
    XCTAssertEqual(msgDescriptor2.messageExtensionRanges[5].start, 9)
    XCTAssertEqual(msgDescriptor2.messageExtensionRanges[6].start, 100)
    XCTAssertEqual(msgDescriptor2.messageExtensionRanges[7].start, 126)
    XCTAssertEqual(msgDescriptor2.messageExtensionRanges[8].start, 111)

    // Check sorting/merging
    XCTAssertEqual(msgDescriptor2._normalizedExtensionRanges.count, 5)
    XCTAssertEqual(msgDescriptor2._normalizedExtensionRanges[0].lowerBound, 1)
    XCTAssertEqual(msgDescriptor2._normalizedExtensionRanges[0].upperBound, 5)
    XCTAssertEqual(msgDescriptor2._normalizedExtensionRanges[1].lowerBound, 7)
    XCTAssertEqual(msgDescriptor2._normalizedExtensionRanges[1].upperBound, 8)
    XCTAssertEqual(msgDescriptor2._normalizedExtensionRanges[2].lowerBound, 9)
    XCTAssertEqual(msgDescriptor2._normalizedExtensionRanges[2].upperBound, 10)
    XCTAssertEqual(msgDescriptor2._normalizedExtensionRanges[3].lowerBound, 100)
    XCTAssertEqual(msgDescriptor2._normalizedExtensionRanges[3].upperBound, 121)
    XCTAssertEqual(msgDescriptor2._normalizedExtensionRanges[4].lowerBound, 126)
    XCTAssertEqual(msgDescriptor2._normalizedExtensionRanges[4].upperBound, 131)


    // Check the "ambitious" merging.
    XCTAssertEqual(msgDescriptor2._ambitiousExtensionRanges.count, 3)
    XCTAssertEqual(msgDescriptor2._ambitiousExtensionRanges[0].lowerBound, 1)
    XCTAssertEqual(msgDescriptor2._ambitiousExtensionRanges[0].upperBound, 5)
    XCTAssertEqual(msgDescriptor2._ambitiousExtensionRanges[1].lowerBound, 7)
    XCTAssertEqual(msgDescriptor2._ambitiousExtensionRanges[1].upperBound, 121)
    XCTAssertEqual(msgDescriptor2._ambitiousExtensionRanges[2].lowerBound, 126)
    XCTAssertEqual(msgDescriptor2._ambitiousExtensionRanges[2].upperBound, 131)

    let msgDescriptor3 = descriptorSet.descriptor(named: "swift_descriptor_test.MsgExtensionRangeOrderingNoMerging")!
    // Quick check of what should be in the proto file
    XCTAssertEqual(msgDescriptor3.messageExtensionRanges.count, 3)
    XCTAssertEqual(msgDescriptor3.messageExtensionRanges[0].start, 3)
    XCTAssertEqual(msgDescriptor3.messageExtensionRanges[1].start, 7)
    XCTAssertEqual(msgDescriptor3.messageExtensionRanges[2].start, 16)

    // Check sorting/merging
    XCTAssertEqual(msgDescriptor3._normalizedExtensionRanges.count, 3)
    XCTAssertEqual(msgDescriptor3._normalizedExtensionRanges[0].lowerBound, 3)
    XCTAssertEqual(msgDescriptor3._normalizedExtensionRanges[0].upperBound, 6)
    XCTAssertEqual(msgDescriptor3._normalizedExtensionRanges[1].lowerBound, 7)
    XCTAssertEqual(msgDescriptor3._normalizedExtensionRanges[1].upperBound, 13)
    XCTAssertEqual(msgDescriptor3._normalizedExtensionRanges[2].lowerBound, 16)
    XCTAssertEqual(msgDescriptor3._normalizedExtensionRanges[2].upperBound, 21)

    // Check the "ambitious" merging.
    XCTAssertEqual(msgDescriptor3._ambitiousExtensionRanges.count, 3)
    XCTAssertEqual(msgDescriptor3._ambitiousExtensionRanges[0].lowerBound, 3)
    XCTAssertEqual(msgDescriptor3._ambitiousExtensionRanges[0].upperBound, 6)
    XCTAssertEqual(msgDescriptor3._ambitiousExtensionRanges[1].lowerBound, 7)
    XCTAssertEqual(msgDescriptor3._ambitiousExtensionRanges[1].upperBound, 13)
    XCTAssertEqual(msgDescriptor3._ambitiousExtensionRanges[2].lowerBound, 16)
    XCTAssertEqual(msgDescriptor3._ambitiousExtensionRanges[2].upperBound, 21)
  }

  func testEnumValueAliasing() throws {
    let txt = [
      "name: \"test.proto\"",
      "syntax: \"proto2\"",
      "enum_type {",
      "  name: \"TestEnum\"",
      "  options {",
      "     allow_alias: true",
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_FOO\"",
      "    number: 0",  // Primary
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_BAR\"",
      "    number: 1",
      "  }",
      "  value {",
      "    name: \"TESTENUM_FOO\"",
      "    number: 0",  // Alias
      "  }",
      "  value {",
      "    name: \"_FOO\"",
      "    number: 0",  // Alias
      "  }",
      "  value {",
      "    name: \"FOO\"",
      "    number: 0",  // Alias
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_ALIAS\"",
      "    number: 0",  // Alias (unique name)
      "  }",
      "}"
    ]

    let fileProto: Google_Protobuf_FileDescriptorProto
    do {
      fileProto = try Google_Protobuf_FileDescriptorProto(textFormatStrings: txt)
    } catch let e {
      XCTFail("Error: \(e)")
      return
    }

    let descriptorSet = DescriptorSet(protos: [fileProto])
    let e = descriptorSet.enumDescriptor(named: "TestEnum")!
    let values = e.values
    XCTAssertEqual(values.count, 6)

    let aliasInfo = EnumDescriptor.ValueAliasInfo(enumDescriptor: e)

    // Check mainValues

    XCTAssertEqual(aliasInfo.mainValues.count, 2)
    XCTAssertIdentical(aliasInfo.mainValues[0], e.values[0])
    XCTAssertIdentical(aliasInfo.mainValues[1], e.values[1])

    // Check aliases(_:)

    XCTAssertEqual(aliasInfo.aliases(e.values[0])!.count, 4)
    XCTAssertIdentical(aliasInfo.aliases(e.values[0])![0], e.values[2])
    XCTAssertIdentical(aliasInfo.aliases(e.values[0])![1], e.values[3])
    XCTAssertIdentical(aliasInfo.aliases(e.values[0])![2], e.values[4])
    XCTAssertIdentical(aliasInfo.aliases(e.values[0])![3], e.values[5])
    XCTAssertNil(aliasInfo.aliases(e.values[1]))  // primary with no aliases
    XCTAssertNil(aliasInfo.aliases(e.values[2]))  // it itself is an alias
    XCTAssertNil(aliasInfo.aliases(e.values[3]))  // it itself is an alias
    XCTAssertNil(aliasInfo.aliases(e.values[4]))  // it itself is an alias
    XCTAssertNil(aliasInfo.aliases(e.values[5]))  // it itself is an alias

    // Check original(of:)

    XCTAssertNil(aliasInfo.original(of: e.values[0]))
    XCTAssertNil(aliasInfo.original(of: e.values[1]))
    XCTAssertIdentical(aliasInfo.original(of: e.values[2]), e.values[0])
    XCTAssertIdentical(aliasInfo.original(of: e.values[3]), e.values[0])
    XCTAssertIdentical(aliasInfo.original(of: e.values[4]), e.values[0])
    XCTAssertIdentical(aliasInfo.original(of: e.values[5]), e.values[0])
  }

  func test_File_computeImports_noImportPublic() {
    let configText = """
      mapping { module_name: "foo", proto_file_path: "file" }
      mapping { module_name: "bar", proto_file_path: "dir1/file" }
      mapping { module_name: "baz", proto_file_path: ["dir2/file","file4"] }
      mapping { module_name: "foo", proto_file_path: "file5" }
    """

    let config = try! SwiftProtobuf_GenSwift_ModuleMappings(textFormatString: configText)
    let mapper = try! ProtoFileToModuleMappings(moduleMappingsProto: config)

    let fileProtos = [
      FileDescriptorProto(name: "file"),
      FileDescriptorProto(name: "google/protobuf/any.proto", package: "google.protobuf"),
      FileDescriptorProto(name: "dir1/file", dependencies: ["file"]),
      FileDescriptorProto(name: "dir2/file", dependencies: ["google/protobuf/any.proto"]),
      FileDescriptorProto(name: "file4", dependencies: ["dir2/file", "dir1/file", "file"]),
      FileDescriptorProto(name: "file5", dependencies: ["file"]),
    ]
    let descSet = DescriptorSet(protos: fileProtos)

    // ( filename, imports, implOnly imports )
    let tests: [(String, String, String)] = [
      ( "file", "", "" ),
      ( "dir1/file", "import foo", "@_implementationOnly import foo" ),
      ( "dir2/file", "", "" ),
      ( "file4", "import bar\nimport foo", "@_implementationOnly import bar\n@_implementationOnly import foo" ),
      ( "file5", "", "" ),
    ]

    for (name, expected, expectedImplOnly) in tests {
      let fileDesc = descSet.files.filter{ $0.name == name }.first!
      do {  // reexportPublicImports: false, asImplementationOnly: false
        let namer =
          SwiftProtobufNamer(currentFile: fileDesc,
                             protoFileToModuleMappings: mapper)
        let result = fileDesc.computeImports(namer: namer, reexportPublicImports: false, asImplementationOnly: false)
        XCTAssertEqual(result, expected, "Looking for \(name)")
      }
      do {  // reexportPublicImports: true, asImplementationOnly: false - No `import publc`, same as previous
        let namer =
          SwiftProtobufNamer(currentFile: fileDesc,
                             protoFileToModuleMappings: mapper)
        let result = fileDesc.computeImports(namer: namer, reexportPublicImports: true, asImplementationOnly: false)
        XCTAssertEqual(result, expected, "Looking for \(name)")
      }
      do {  // reexportPublicImports: false, asImplementationOnly: true
        let namer =
          SwiftProtobufNamer(currentFile: fileDesc,
                             protoFileToModuleMappings: mapper)
        let result = fileDesc.computeImports(namer: namer, reexportPublicImports: false, asImplementationOnly: true)
        XCTAssertEqual(result, expectedImplOnly, "Looking for \(name)")
      }
    }
  }

  func test_File_computeImports_PublicImports() {
    // See the notes on computeImports(namer:reexportPublicImports:asImplementationOnly:)
    // about how public import complicate things.

    // Given:
    //
    //  + File: a.proto
    //    message A {}
    //
    //    enum E {
    //      E_UNSET = 0;
    //      E_A = 1;
    //      E_B = 2;
    //    }
    //
    //  + File: imports_a_publicly.proto
    //    import public "a.proto";
    //
    //    message ImportsAPublicly {
    //      optional A a = 1;
    //      optional E e = 2;
    //    }
    //
    //  + File: imports_imports_a_publicly.proto
    //    import public "imports_a_publicly.proto";
    //
    //    message ImportsImportsAPublicly {
    //      optional A a = 1;
    //    }
    //
    //  + File: uses_a_transitively.proto
    //    import "imports_a_publicly.proto";
    //
    //    message UsesATransitively {
    //      optional A a = 1;
    //    }
    //
    //  + File: uses_a_transitively2.proto
    //    import "imports_imports_a_publicly.proto";
    //
    //    message UsesATransitively2 {
    //      optional A a = 1;
    //    }
    //
    // With a mapping file of:
    //
    //    mapping {
    //      module_name: "A"
    //      proto_file_path: "a.proto"
    //    }
    //    mapping {
    //      module_name: "ImportsAPublicly"
    //      proto_file_path: "imports_a_publicly.proto"
    //    }
    //    mapping {
    //      module_name: "ImportsImportsAPublicly"
    //      proto_file_path: "imports_imports_a_publicly.proto"
    //    }

    let configText = """
      mapping { module_name: "A", proto_file_path: "a.proto" }
      mapping { module_name: "ImportsAPublicly", proto_file_path: "imports_a_publicly.proto" }
      mapping { module_name: "ImportsImportsAPublicly", proto_file_path: "imports_imports_a_publicly.proto" }
    """

    let config = try! SwiftProtobuf_GenSwift_ModuleMappings(textFormatString: configText)
    let mapper = try! ProtoFileToModuleMappings(moduleMappingsProto: config)

    let fileProtos = [
      try! FileDescriptorProto(textFormatString: """
        name: "a.proto"
        message_type {
          name: "A"
        }
        enum_type {
          name: "E"
          value {
            name: "E_UNSET"
            number: 0
          }
          value {
            name: "E_A"
            number: 1
          }
          value {
            name: "E_B"
            number: 2
          }
        }
      """),
      try! FileDescriptorProto(textFormatString: """
        name: "imports_a_publicly.proto"
        dependency: "a.proto"
        message_type {
          name: "ImportsAPublicly"
          field {
            name: "a"
            number: 1
            label: LABEL_OPTIONAL
            type: TYPE_MESSAGE
            type_name: ".A"
            json_name: "a"
          }
          field {
            name: "e"
            number: 2
            label: LABEL_OPTIONAL
            type: TYPE_ENUM
            type_name: ".E"
            json_name: "e"
          }
        }
        public_dependency: 0
      """),
      try! FileDescriptorProto(textFormatString: """
        name: "imports_imports_a_publicly.proto"
        dependency: "imports_a_publicly.proto"
        message_type {
          name: "ImportsImportsAPublicly"
          field {
            name: "a"
            number: 1
            label: LABEL_OPTIONAL
            type: TYPE_MESSAGE
            type_name: ".A"
            json_name: "a"
          }
        }
        public_dependency: 0
      """),
      try! FileDescriptorProto(textFormatString: """
        name: "uses_a_transitively.proto"
        dependency: "imports_a_publicly.proto"
        message_type {
          name: "UsesATransitively"
          field {
            name: "a"
            number: 1
            label: LABEL_OPTIONAL
            type: TYPE_MESSAGE
            type_name: ".A"
            json_name: "a"
          }
        }
      """),
      try! FileDescriptorProto(textFormatString: """
        name: "uses_a_transitively2.proto"
        dependency: "imports_imports_a_publicly.proto"
        message_type {
          name: "UsesATransitively2"
          field {
            name: "a"
            number: 1
            label: LABEL_OPTIONAL
            type: TYPE_MESSAGE
            type_name: ".A"
            json_name: "a"
          }
        }
      """),
    ]
    let descSet = DescriptorSet(protos: fileProtos)

    // ( filename, imports, reExportPublicImports imports, implOnly imports )
    let tests: [(String, String, String, String)] = [
      ( "a.proto",
        "", "", "" ),
      ( "imports_a_publicly.proto",
        "import A",
        "// Use of 'import public' causes re-exports:\n@_exported import enum A.E\n@_exported import struct A.A",
        "@_implementationOnly import A" ),
      ( "imports_imports_a_publicly.proto",
        "import ImportsAPublicly",
        "// Use of 'import public' causes re-exports:\n@_exported import enum A.E\n@_exported import struct A.A\n@_exported import struct ImportsAPublicly.ImportsAPublicly",
        "@_implementationOnly import ImportsAPublicly" ),
      ( "uses_a_transitively.proto",
        "import ImportsAPublicly",  // this reexports A, so we don't directly pull in A.
        "import ImportsAPublicly",  // just a plain `import`, nothing to re-export.
        "@_implementationOnly import ImportsAPublicly" ),
      ( "uses_a_transitively2.proto",
        "import ImportsImportsAPublicly",  // this chain reexports A, so we don't directly pull in A.
        "import ImportsImportsAPublicly",  // just a plain `import`, nothing to re-export.
        "@_implementationOnly import ImportsImportsAPublicly" ),
    ]

    for (name, expected, expectedReExport, expectedImplOnly) in tests {
      let fileDesc = descSet.files.filter{ $0.name == name }.first!
      do {  // reexportPublicImports: false, asImplementationOnly: false
        let namer =
          SwiftProtobufNamer(currentFile: fileDesc,
                             protoFileToModuleMappings: mapper)
        let result = fileDesc.computeImports(namer: namer, reexportPublicImports: false, asImplementationOnly: false)
        XCTAssertEqual(result, expected, "Looking for \(name)")
      }
      do {  // reexportPublicImports: true, asImplementationOnly: false
        let namer =
          SwiftProtobufNamer(currentFile: fileDesc,
                             protoFileToModuleMappings: mapper)
        let result = fileDesc.computeImports(namer: namer, reexportPublicImports: true, asImplementationOnly: false)
        XCTAssertEqual(result, expectedReExport, "Looking for \(name)")
      }
      do {  // reexportPublicImports: false, asImplementationOnly: true
        let namer =
          SwiftProtobufNamer(currentFile: fileDesc,
                             protoFileToModuleMappings: mapper)
        let result = fileDesc.computeImports(namer: namer, reexportPublicImports: false, asImplementationOnly: true)
        XCTAssertEqual(result, expectedImplOnly, "Looking for \(name)")
      }
    }
  }

}
