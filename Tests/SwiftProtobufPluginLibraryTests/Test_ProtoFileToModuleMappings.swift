// Tests/SwiftProtobufPluginLibraryTests/Test_ProtoFileToModuleMappings.swift - Test ProtoFile to Modules helper
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobuf
import SwiftProtobufPluginLibrary
import SwiftProtobufTestHelpers
import XCTest

// Helpers to make test cases.

private typealias FileDescriptorProto = Google_Protobuf_FileDescriptorProto

final class Test_ProtoFileToModuleMappings: XCTestCase {

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
            (
                "mapping { module_name: \"good\", proto_file_path: \"a\" }\n"
                    + "mapping { module_name: \"good\", proto_file_path: \"b\" }", 2, 1
            ),

            // Two mapping {}, different modules.
            (
                "mapping { module_name: \"one\", proto_file_path: \"a\" }\n"
                    + "mapping { module_name: \"two\", proto_file_path: \"b\" }", 2, 2
            ),

            // Same file listed twice; odd, but ok since no conflict.
            ("mapping { module_name: \"foo\", proto_file_path: [\"abc\", \"abc\"] }", 1, 1),

            // Same module/file listing; odd, but ok since no conflict.
            (
                "mapping { module_name: \"foo\", proto_file_path: [\"mno\", \"abc\"] }\n"
                    + "mapping { module_name: \"foo\", proto_file_path: [\"abc\", \"xyz\"] }", 3, 1
            ),

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
                XCTAssert(mapper.hasMappings == (expectMappings != 0), "Index: \(idx)")
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
            (
                "mapping { module_name: \"\", proto_file_path: [\"foo\", \"bar\"] }",
                .entryMissingModuleName(mappingIndex: 0)
            ),

            // Throw some on a second entry just to check that also.
            (
                "mapping { module_name: \"good\", proto_file_path: \"file.proto\" }\n" + "mapping { }",
                .entryMissingModuleName(mappingIndex: 1)
            ),
            (
                "mapping { module_name: \"good\", proto_file_path: \"file.proto\" }\n"
                    + "mapping { module_name: \"foo\" }",
                .entryHasNoProtoPaths(mappingIndex: 1)
            ),

            // Duplicates

            (
                "mapping { module_name: \"foo\", proto_file_path: \"abc\" }\n"
                    + "mapping { module_name: \"bar\", proto_file_path: \"abc\" }",
                .duplicateProtoPathMapping(path: "abc", firstModule: "foo", secondModule: "bar")
            ),

            (
                "mapping { module_name: \"foo\", proto_file_path: \"abc\" }\n"
                    + "mapping { module_name: \"bar\", proto_file_path: \"xyz\" }\n"
                    + "mapping { module_name: \"baz\", proto_file_path: \"abc\" }",
                .duplicateProtoPathMapping(path: "abc", firstModule: "foo", secondModule: "baz")
            ),
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
            ("file", "foo"),
            ("dir1/file", "bar"),
            ("dir2/file", "baz"),
            ("file4", "baz"),
            ("file5", "foo"),

            ("", nil),
            ("not found", nil),
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
            FileDescriptorProto(name: "google/protobuf/any.proto"),
            FileDescriptorProto(name: "dir1/file", dependencies: ["file"]),
            FileDescriptorProto(name: "dir2/file", dependencies: ["google/protobuf/any.proto"]),
            FileDescriptorProto(name: "file4", dependencies: ["dir2/file", "dir1/file", "file"]),
            FileDescriptorProto(name: "file5", dependencies: ["file"]),
        ]
        let descSet = DescriptorSet(protos: fileProtos)

        // ( filename, [deps] )
        let tests: [(String, [String]?)] = [
            ("file", nil),
            ("dir1/file", ["foo"]),
            ("dir2/file", nil),
            ("file4", ["bar", "foo"]),
            ("file5", nil),
        ]

        for (name, expected) in tests {
            let fileDesc = descSet.files.filter { $0.name == name }.first!
            let result = mapper.neededModules(forFile: fileDesc)
            if let expected = expected {
                XCTAssertEqual(result!, expected, "Looking for \(name)")
            } else {
                XCTAssertNil(result, "Looking for \(name)")
            }
        }
    }

    func test_neededModules_forFile_PublicImports() {
        // See the note in neededModules(forFile:) about how public import complicate things.

        // Given:
        //
        //  + File: a.proto
        //    message A {}
        //
        //  + File: imports_a_publicly.proto
        //    import public "a.proto";
        //
        //    message ImportsAPublicly {
        //      A a = 1;
        //    }
        //
        //  + File: imports_imports_a_publicly.proto
        //    import public "imports_a_publicly.proto";
        //
        //    message ImportsImportsAPublicly {
        //      A a = 1;
        //    }
        //
        //  + File: uses_a_transitively.proto
        //    import "imports_a_publicly.proto";
        //
        //    message UsesATransitively {
        //      A a = 1;
        //    }
        //
        //  + File: uses_a_transitively2.proto
        //    import "imports_imports_a_publicly.proto";
        //
        //    message UsesATransitively2 {
        //      A a = 1;
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

        let configText = [
            "mapping { module_name: \"A\", proto_file_path: \"a.proto\" }",
            "mapping { module_name: \"ImportsAPublicly\", proto_file_path: \"imports_a_publicly.proto\" }",
            "mapping { module_name: \"ImportsImportsAPublicly\", proto_file_path: \"imports_imports_a_publicly.proto\" }",
        ].joined(separator: "\n")

        let config = try! SwiftProtobuf_GenSwift_ModuleMappings(textFormatString: configText)
        let mapper = try! ProtoFileToModuleMappings(moduleMappingsProto: config)

        let fileProtos = [
            FileDescriptorProto(name: "a.proto"),
            FileDescriptorProto(
                name: "imports_a_publicly.proto",
                dependencies: ["a.proto"],
                publicDependencies: [0]
            ),
            FileDescriptorProto(
                name: "imports_imports_a_publicly.proto",
                dependencies: ["imports_a_publicly.proto"],
                publicDependencies: [0]
            ),
            FileDescriptorProto(
                name: "uses_a_transitively.proto",
                dependencies: ["imports_a_publicly.proto"]
            ),
            FileDescriptorProto(
                name: "uses_a_transitively2.proto",
                dependencies: ["imports_imports_a_publicly.proto"]
            ),
        ]
        let descSet = DescriptorSet(protos: fileProtos)

        // ( filename, [deps] )
        let tests: [(String, [String]?)] = [
            ("a.proto", nil),
            ("imports_a_publicly.proto", ["A"]),
            ("imports_imports_a_publicly.proto", ["A", "ImportsAPublicly"]),
            ("uses_a_transitively.proto", ["A", "ImportsAPublicly"]),
            ("uses_a_transitively2.proto", ["A", "ImportsAPublicly", "ImportsImportsAPublicly"]),
        ]

        for (name, expected) in tests {
            let fileDesc = descSet.files.filter { $0.name == name }.first!
            let result = mapper.neededModules(forFile: fileDesc)
            if let expected = expected {
                XCTAssertEqual(result!, expected, "Looking for \(name)")
            } else {
                XCTAssertNil(result, "Looking for \(name)")
            }
        }
    }

    func test_Initialization_MultipleProtos() {
        let baselineEntries = SwiftProtobufInfo.bundledProtoFiles.count
        let baselineModules = 1

        let config1Text = """
        mapping { module_name: "ModuleA", proto_file_path: ["a.proto", "shared.proto"] }
        """
        let config2Text = """
        mapping { module_name: "ModuleB", proto_file_path: "b.proto" }
        mapping { module_name: "ModuleA", proto_file_path: "shared.proto" }
        """

        do {
            let proto1 = try SwiftProtobuf_GenSwift_ModuleMappings(textFormatString: config1Text)
            let proto2 = try SwiftProtobuf_GenSwift_ModuleMappings(textFormatString: config2Text)

            let mapper = try ProtoFileToModuleMappings(moduleMappingsProtos: [proto1, proto2])
            XCTAssertEqual(mapper.mappings.count, 3 + baselineEntries)
            XCTAssertEqual(Set(mapper.mappings.values).count, 2 + baselineModules)
            XCTAssertEqual(mapper.mappings["a.proto"], "ModuleA")
            XCTAssertEqual(mapper.mappings["b.proto"], "ModuleB")
            XCTAssertEqual(mapper.mappings["shared.proto"], "ModuleA")
            XCTAssertTrue(mapper.hasMappings)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // Conflicting mappings across protos should fail.
        let conflictingConfigText = """
        mapping { module_name: "ModuleConflict", proto_file_path: "shared.proto" }
        """
        do {
            let proto1 = try SwiftProtobuf_GenSwift_ModuleMappings(textFormatString: config1Text)
            let protoConflict = try SwiftProtobuf_GenSwift_ModuleMappings(textFormatString: conflictingConfigText)
            XCTAssertThrowsError(try ProtoFileToModuleMappings(moduleMappingsProtos: [proto1, protoConflict])) { error in
                guard let loadError = error as? ProtoFileToModuleMappings.LoadError else {
                    XCTFail("Expected LoadError, got \(error)")
                    return
                }
                XCTAssertEqual(
                    loadError,
                    .duplicateProtoPathMapping(
                        path: "shared.proto",
                        firstModule: "ModuleA",
                        firstPath: nil,
                        secondModule: "ModuleConflict",
                        secondPath: nil
                    )
                )
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_Initialization_MultiplePaths() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let path1 = tempDir.appendingPathComponent("map1.asciipb").path
        let path2 = tempDir.appendingPathComponent("map2.asciipb").path
        let pathConflict = tempDir.appendingPathComponent("conflict.asciipb").path
        let pathInvalidEntry = tempDir.appendingPathComponent("invalid.asciipb").path

        let config1Text = """
        mapping { module_name: "Core", proto_file_path: ["core1.proto", "core2.proto"] }
        """
        let config2Text = """
        mapping { module_name: "Auth", proto_file_path: "auth.proto" }
        """
        let configConflictText = """
        mapping { module_name: "Other", proto_file_path: "core1.proto" }
        """
        let configInvalidEntryText = """
        mapping { module_name: "Valid", proto_file_path: "valid.proto" }
        mapping { module_name: "", proto_file_path: "bad.proto" }
        """

        try config1Text.write(toFile: path1, atomically: true, encoding: .utf8)
        try config2Text.write(toFile: path2, atomically: true, encoding: .utf8)
        try configConflictText.write(toFile: pathConflict, atomically: true, encoding: .utf8)
        try configInvalidEntryText.write(toFile: pathInvalidEntry, atomically: true, encoding: .utf8)

        let mapper = try ProtoFileToModuleMappings(paths: [path1, path2])
        XCTAssertEqual(mapper.mappings["core1.proto"], "Core")
        XCTAssertEqual(mapper.mappings["core2.proto"], "Core")
        XCTAssertEqual(mapper.mappings["auth.proto"], "Auth")

        // Fail to open missing file
        let nonExistentPath = tempDir.appendingPathComponent("missing.asciipb").path
        XCTAssertThrowsError(try ProtoFileToModuleMappings(paths: [path1, nonExistentPath])) { error in
            guard let loadError = error as? ProtoFileToModuleMappings.LoadError else {
                XCTFail("Expected LoadError, got \(error)")
                return
            }
            XCTAssertEqual(loadError, .failToOpen(path: nonExistentPath))
            XCTAssertEqual(loadError.description, "Failed to open '\(nonExistentPath)'")
        }

        // Duplicate conflict with source paths
        XCTAssertThrowsError(try ProtoFileToModuleMappings(paths: [path1, pathConflict])) { error in
            guard let loadError = error as? ProtoFileToModuleMappings.LoadError else {
                XCTFail("Expected LoadError, got \(error)")
                return
            }
            XCTAssertEqual(
                loadError,
                .duplicateProtoPathMapping(
                    path: "core1.proto",
                    firstModule: "Core",
                    firstPath: path1,
                    secondModule: "Other",
                    secondPath: pathConflict
                )
            )
            XCTAssertEqual(
                loadError.description,
                "Duplicate mapping for proto 'core1.proto': 'Core' (in '\(path1)') vs 'Other' (in '\(pathConflict)')"
            )
        }

        // Invalid entry in second file reports file-local index (1) and path
        XCTAssertThrowsError(try ProtoFileToModuleMappings(paths: [path1, pathInvalidEntry])) { error in
            guard let loadError = error as? ProtoFileToModuleMappings.LoadError else {
                XCTFail("Expected LoadError, got \(error)")
                return
            }
            XCTAssertEqual(
                loadError,
                .entryMissingModuleName(mappingIndex: 1, path: pathInvalidEntry)
            )
            XCTAssertEqual(
                loadError.description,
                "Mapping entry 1 in '\(pathInvalidEntry)' is missing a module_name"
            )
        }
    }

}
