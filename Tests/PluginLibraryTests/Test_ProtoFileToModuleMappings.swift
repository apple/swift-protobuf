// Tests/PluginLibraryTests/Test_ProtoFileToModuleMappings.swift - Test ProtoFile to Modules helper
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import XCTest
@testable import PluginLibrary

// Support equality to simplify testing of getting the correct errors.
extension ProtoFileToModuleMappings.LoadError: Equatable {
  public static func ==(lhs: ProtoFileToModuleMappings.LoadError, rhs: ProtoFileToModuleMappings.LoadError) -> Bool {
    switch (lhs, rhs) {
    case (.entryMissingModuleName(let l), .entryMissingModuleName(let r)): return l == r
    case (.entryHasNoProtoPaths(let l), .entryHasNoProtoPaths(let r)): return l == r
    case (.duplicateProtoPathMapping(let l1, let l2, let l3),
          .duplicateProtoPathMapping(let r1, let r2, let r3)): return l1 == r1 && l2 == r2 && l3 == r3
    default: return false
    }
  }
}

// Helpers to make test cases.

typealias FileDescriptorProto = Google_Protobuf_FileDescriptorProto

extension Google_Protobuf_FileDescriptorProto {
  init(name: String, dependencies: [String] = []) {
    self.init()
    self.name = name
    dependency = dependencies
  }
}

class Test_ProtoFileToModuleMappings: XCTestCase {

  func test_Initialization() {
    // ProtoFileToModuleMappings always includes mappings for the protos that
    // ship with the library, so they will show in the counts below.
    let baselineEntries = SwiftProtobufInfo.bundledProtoFiles.count
    let baselineModules = 1  // Since those files are in SwiftProtobuf.

    // (config, num_expected_mappings, num_expected_modules)
    let tests: [(String, Int, Int)] = [
      ("", 0, 0),

      ("mapping { module_name: \"good\", proto_file_path: \"file.proto\" }", 1, 1),

      ("mapping { module_name: \"good\", proto_file_path: [\"a\",\"b\"] }", 2, 1),

      // Two mapping {}, same module.
      ("mapping { module_name: \"good\", proto_file_path: \"a\" }\n" +
       "mapping { module_name: \"good\", proto_file_path: \"b\" }", 2, 1),

      // Two mapping {}, different modules.
      ("mapping { module_name: \"one\", proto_file_path: \"a\" }\n" +
       "mapping { module_name: \"two\", proto_file_path: \"b\" }", 2, 2),
    ]

    for (idx, (configText, expectMappings, expectedModules)) in tests.enumerated() {
      let config: SwiftProtobuf_GenSwift_ModuleMappings
      do {
        config = try SwiftProtobuf_GenSwift_ModuleMappings(textFormatString: configText)
      } catch {
        XCTFail("Index: \(idx) - Test case wasn't valid TextFormat")
        continue
      }

      do {
        let mapper = try ProtoFileToModuleMappings(moduleMappingsProto: config)
        XCTAssertEqual(mapper.mappings.count, expectMappings + baselineEntries, "Index: \(idx)")
        XCTAssertEqual(Set(mapper.mappings.values).count, expectedModules + baselineModules, "Index: \(idx)")
      } catch let error {
        XCTFail("Index \(idx) - Unexpected error: \(error)")
      }
    }
  }

  func test_Initialization_InvalidConfigs() {
    // This are valid text format, but not valid config protos.
    // (input, expected_error_type)
    let partialConfigs: [(String, ProtoFileToModuleMappings.LoadError)] = [
      // No module or proto files
      ("mapping { }", .entryMissingModuleName(mappingIndex: 0)),

      // No proto files
      ("mapping { module_name: \"foo\" }", .entryHasNoProtoPaths(mappingIndex: 0)),

      // No module
      ("mapping { proto_file_path: [\"foo\"] }", .entryMissingModuleName(mappingIndex: 0)),
      ("mapping { proto_file_path: [\"foo\", \"bar\"] }", .entryMissingModuleName(mappingIndex: 0)),

      // Empty module name.
      ("mapping { module_name: \"\" }", .entryMissingModuleName(mappingIndex: 0)),
      ("mapping { module_name: \"\", proto_file_path: [\"foo\"] }", .entryMissingModuleName(mappingIndex: 0)),
      ("mapping { module_name: \"\", proto_file_path: [\"foo\", \"bar\"] }", .entryMissingModuleName(mappingIndex: 0)),

      // Throw some on a second entry just to check that also.
      ("mapping { module_name: \"good\", proto_file_path: \"file.proto\" }\n" +
       "mapping { }",
       .entryMissingModuleName(mappingIndex: 1)),
      ("mapping { module_name: \"good\", proto_file_path: \"file.proto\" }\n" +
       "mapping { module_name: \"foo\" }",
       .entryHasNoProtoPaths(mappingIndex: 1)),

      // Duplicates

      ("mapping { module_name: \"foo\", proto_file_path: [\"abc\", \"abc\"] }",
       .duplicateProtoPathMapping(path: "abc", firstModule: "foo", secondModule: "foo")),

      ("mapping { module_name: \"foo\", proto_file_path: \"abc\" }\n" +
       "mapping { module_name: \"bar\", proto_file_path: \"abc\" }",
       .duplicateProtoPathMapping(path: "abc", firstModule: "foo", secondModule: "bar")),

      ("mapping { module_name: \"foo\", proto_file_path: \"abc\" }\n" +
       "mapping { module_name: \"foo\", proto_file_path: \"abc\" }",
       .duplicateProtoPathMapping(path: "abc", firstModule: "foo", secondModule: "foo")),

      ("mapping { module_name: \"foo\", proto_file_path: \"abc\" }\n" +
       "mapping { module_name: \"bar\", proto_file_path: \"xyz\" }\n" +
       "mapping { module_name: \"baz\", proto_file_path: \"abc\" }",
       .duplicateProtoPathMapping(path: "abc", firstModule: "foo", secondModule: "baz")),
    ]

    for (idx, (configText, expected)) in partialConfigs.enumerated() {
      let config: SwiftProtobuf_GenSwift_ModuleMappings
      do {
        config = try SwiftProtobuf_GenSwift_ModuleMappings(textFormatString: configText)
      } catch {
        XCTFail("Index: \(idx) - Test case wasn't valid TextFormat")
        continue
      }

      do {
        let _ = try ProtoFileToModuleMappings(moduleMappingsProto: config)
        XCTFail("Shouldn't have gotten here, index \(idx)")
      } catch let error as ProtoFileToModuleMappings.LoadError {
        XCTAssertEqual(error, expected, "Index \(idx)")
      } catch let error {
        XCTFail("Index \(idx) - Unexpected error: \(error)")
      }
    }
  }

  func test_moduleName_forFile() {
    let configText = [
      "mapping { module_name: \"foo\", proto_file_path: \"file\" }",
      "mapping { module_name: \"bar\", proto_file_path: \"dir1/file\" }",
      "mapping { module_name: \"baz\", proto_file_path: [\"dir2/file\",\"file4\"] }",
      "mapping { module_name: \"foo\", proto_file_path: \"file5\" }",
    ].joined(separator: "\n")

    let config = try! SwiftProtobuf_GenSwift_ModuleMappings(textFormatString: configText)
    let mapper = try! ProtoFileToModuleMappings(moduleMappingsProto: config)

    let tests: [(String, String?)] = [
      ( "file", "foo" ),
      ( "dir1/file", "bar" ),
      ( "dir2/file", "baz" ),
      ( "file4", "baz" ),
      ( "file5", "foo" ),

      ( "", nil ),
      ( "not found", nil ),
    ]

    for (name, expected) in tests {
      let descSet = DescriptorSet(protos: [FileDescriptorProto(name: name)])
      XCTAssertEqual(mapper.moduleName(forFile: descSet.files.first!), expected, "Looking for \(name)")
    }
  }

  func test_neededModules_forFile() {
    let configText = [
      "mapping { module_name: \"foo\", proto_file_path: \"file\" }",
      "mapping { module_name: \"bar\", proto_file_path: \"dir1/file\" }",
      "mapping { module_name: \"baz\", proto_file_path: [\"dir2/file\",\"file4\"] }",
      "mapping { module_name: \"foo\", proto_file_path: \"file5\" }",
      ].joined(separator: "\n")

    let config = try! SwiftProtobuf_GenSwift_ModuleMappings(textFormatString: configText)
    let mapper = try! ProtoFileToModuleMappings(moduleMappingsProto: config)

    let fileProtos = [
      FileDescriptorProto(name: "file"),
      FileDescriptorProto(name: "dir1/file", dependencies: ["file"]),
      FileDescriptorProto(name: "dir2/file", dependencies: ["google/protobuf/any.proto"]),
      FileDescriptorProto(name: "file4", dependencies: ["dir2/file", "dir1/file", "file"]),
      FileDescriptorProto(name: "file5", dependencies: ["file"]),
    ]
    let descSet = DescriptorSet(protos: fileProtos)

    // ( filename, [deps] )
    let tests: [(String, [String]?)] = [
      ( "file", nil ),
      ( "dir1/file", ["foo"] ),
      ( "dir2/file", nil ),
      ( "file4", ["bar", "foo"] ),
      ( "file5", nil ),
    ]

    for (name, expected) in tests {
      let fileDesc = descSet.files.filter{ $0.name == name }.first!
      let result = mapper.neededModules(forFile: fileDesc)
      if let expected = expected {
        XCTAssertEqual(result!, expected, "Looking for \(name)")
      } else {
        XCTAssertNil(result, "Looking for \(name)")
      }
    }
  }

}
