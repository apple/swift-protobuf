// Tests/SwiftProtobufPluginLibraryTests/Test_Descriptor.swift - Test Descriptor.swift
//
// Copyright (c) 2014 - 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import XCTest
import SwiftProtobuf
import SwiftProtobufPluginLibrary

fileprivate let testFeatureSetDefaults =
  try! Google_Protobuf_FeatureSetDefaults(serializedBytes: testFeatureSetDefaultBytes,
                                          extensions: SwiftFeatureTest_TestFeatures_Extensions)

fileprivate struct TestContext {
  let descriptorSet: DescriptorSet
  var file: FileDescriptor { return descriptorSet.files.first! }

  init(_ descriptorTextFormat: String) {
    let file = try! Google_Protobuf_FileDescriptorProto(textFormatString: descriptorTextFormat,
                                                        extensions: SwiftFeatureTest_TestFeatures_Extensions)
    descriptorSet = DescriptorSet(protos: [file],
                                  featureSetDefaults: testFeatureSetDefaults,
                                  featureExtensions: [SwiftFeatureTest_Extensions_test])
  }
}

final class Test_Descriptor_FeatureResolution: XCTestCase {

  func testFileLevel_Defaults() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      """)

    let features = context.file.features
    XCTAssertTrue(features.hasSwiftFeatureTest_test)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature1, .value1)
  }

  func testFileLevel_Override() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      options {
        features {
          [swift_feature_test.test] { feature1: ENUM_FEATURE_VALUE2 }
        }
      }
      """)

    let features = context.file.features
    XCTAssertTrue(features.hasSwiftFeatureTest_test)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature1, .value2)  // File override
  }

  func testMessageLevel_Defaults() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      message_type {
        name: "Top"
        nested_type {
          name: "Nested"
        }
      }
      """)

    let topFeatures = context.file.messages.first!.features
    XCTAssertTrue(topFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(topFeatures.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(topFeatures.SwiftFeatureTest_test.feature2, .value1)
    let nestedFeatures = context.file.messages.first!.messages.first!.features
    XCTAssertTrue(nestedFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature2, .value1)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature3, .value1)
  }

  func testMessageLevel_Override() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      options {
        features {
          [swift_feature_test.test] { feature1: ENUM_FEATURE_VALUE2 }
        }
      }
      message_type {
        name: "Top"
        options {
          features {
            [swift_feature_test.test] { feature2: ENUM_FEATURE_VALUE3 }
          }
        }
        nested_type {
          name: "Nested"
          options {
            features {
              [swift_feature_test.test] { feature3: ENUM_FEATURE_VALUE4 }
            }
          }
        }
      }
      """)

    let topFeatures = context.file.messages.first!.features
    XCTAssertTrue(topFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(topFeatures.SwiftFeatureTest_test.feature1, .value2)  // File override
    XCTAssertEqual(topFeatures.SwiftFeatureTest_test.feature2, .value3)  // Top override
    let nestedFeatures = context.file.messages.first!.messages.first!.features
    XCTAssertTrue(nestedFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature1, .value2)  // File override
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature2, .value3)  // Top override
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature3, .value4)  // Nested override
  }

  func testEnumLevel_Defaults() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      enum_type {
        name: "Top"
        value { name: "TOP_UNKNOWN", number: 0 }
        value { name: "TOP_ONE", number: 1 }
      }
      message_type {
        name: "MyMessage"
        enum_type {
          name: "Nested"
          value { name: "NESTED_UNKNOWN", number: 0 }
          value { name: "NESTED_ONE", number: 1 }
        }
      }
      """)

    let topFeatures = context.file.enums.first!.features
    XCTAssertTrue(topFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(topFeatures.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(topFeatures.SwiftFeatureTest_test.feature2, .value1)
    let nestedFeatures = context.file.messages.first!.enums.first!.features
    XCTAssertTrue(nestedFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature2, .value1)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature3, .value1)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature4, .value1)
  }

  func testEnumLevel_Override() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      options {
        features {
          [swift_feature_test.test] { feature1: ENUM_FEATURE_VALUE2 }
        }
      }
      enum_type {
        name: "Top"
        options {
          features {
            [swift_feature_test.test] { feature2: ENUM_FEATURE_VALUE3 }
          }
        }
        value { name: "TOP_UNKNOWN", number: 0 }
        value { name: "TOP_ONE", number: 1 }
      }
      message_type {
        name: "MyMessage"
        options {
          features {
            [swift_feature_test.test] { feature3: ENUM_FEATURE_VALUE4 }
          }
        }
        enum_type {
          name: "Nested"
          options {
            features {
              [swift_feature_test.test] { feature4: ENUM_FEATURE_VALUE5 }
            }
          }
          value { name: "NESTED_UNKNOWN", number: 0 }
          value { name: "NESTED_ONE", number: 1 }
        }
      }
      """)

    let topFeatures = context.file.enums.first!.features
    XCTAssertTrue(topFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(topFeatures.SwiftFeatureTest_test.feature1, .value2)  //  File override
    XCTAssertEqual(topFeatures.SwiftFeatureTest_test.feature2, .value3)  //  "Top" Enum override
    let nestedFeatures = context.file.messages.first!.enums.first!.features
    XCTAssertTrue(nestedFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature1, .value2)  // File override
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature2, .value1)  // default ("Top" Enum override)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature3, .value4)  // Message override
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature4, .value5)  // "Nested" Enum override
  }

  func testEnumValueLevel_Defaults() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      enum_type {
        name: "Top"
        value { name: "TOP_UNKNOWN", number: 0 }
        value { name: "TOP_ONE", number: 1 }
      }
      """)

    let features = context.file.enums.first!.values.first!.features
    XCTAssertTrue(features.hasSwiftFeatureTest_test)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature2, .value1)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature3, .value1)
  }

  func testEnumValueLevel_Override() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      options {
        features {
          [swift_feature_test.test] { feature1: ENUM_FEATURE_VALUE2 }
        }
      }
      enum_type {
        name: "MyEnum"
        options {
          features {
            [swift_feature_test.test] { feature2: ENUM_FEATURE_VALUE3 }
          }
        }
        value {
          name: "TOP_UNKNOWN"
          options {
            features {
              [swift_feature_test.test] { feature3: ENUM_FEATURE_VALUE4 }
            }
          }
          number: 0
        }
        value { name: "TOP_ONE", number: 1 }
      }
      """)

    let features = context.file.enums.first!.values.first!.features
    XCTAssertTrue(features.hasSwiftFeatureTest_test)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature1, .value2)  //  File override
    XCTAssertEqual(features.SwiftFeatureTest_test.feature2, .value3)  //  Enum override
    XCTAssertEqual(features.SwiftFeatureTest_test.feature3, .value4)  //  EnumValue override
  }

  func testExtensionRangeLevel_Defaults() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      message_type {
        name: "MyMessage"
        extension_range { start: 1, end: 100 }
      }
      """)

    let features = context.file.messages.first!.messageExtensionRanges.first!.features
    XCTAssertTrue(features.hasSwiftFeatureTest_test)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature2, .value1)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature3, .value1)
  }

  func testExtensionRangeLevel_Override() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      options {
        features {
          [swift_feature_test.test] { feature1: ENUM_FEATURE_VALUE2 }
        }
      }
      message_type {
        name: "MyMessage"
        options {
          features {
            [swift_feature_test.test] { feature2: ENUM_FEATURE_VALUE3 }
          }
        }
        extension_range {
          start: 1
          end: 100
          options {
            features {
              [swift_feature_test.test] { feature3: ENUM_FEATURE_VALUE4 }
            }
          }
        }
      }
      """)

    let features = context.file.messages.first!.messageExtensionRanges.first!.features
    XCTAssertTrue(features.hasSwiftFeatureTest_test)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature1, .value2)  //  File override
    XCTAssertEqual(features.SwiftFeatureTest_test.feature2, .value3)  //  Message override
    XCTAssertEqual(features.SwiftFeatureTest_test.feature3, .value4)  //  ExtensionRange override
  }

  func testExtensionLevel_Defaults() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      message_type {
        name: "MyMessage"
        extension_range { start: 1, end: 100 }
        extension {
          name: "nested"
          json_name: "nested"
          number: 2
          type: TYPE_STRING
          extendee: ".MyMessage"
        }
      }
      extension {
        name: "top"
        json_name: "top"
        number: 1
        type: TYPE_STRING
        extendee: ".MyMessage"
      }
      """)

    let topFeatures = context.file.extensions.first!.features
    XCTAssertTrue(topFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(topFeatures.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(topFeatures.SwiftFeatureTest_test.feature2, .value1)
    let nestedFeatures = context.file.messages.first!.extensions.first!.features
    XCTAssertTrue(nestedFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature2, .value1)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature3, .value1)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature4, .value1)
  }

  func testExtensionLevel_Override() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      options {
        features {
          [swift_feature_test.test] { feature1: ENUM_FEATURE_VALUE2 }
        }
      }
      message_type {
        name: "MyMessage"
        options {
          features {
            [swift_feature_test.test] { feature3: ENUM_FEATURE_VALUE4 }
          }
        }
        extension_range { start: 1, end: 100 }
        extension {
          name: "nested"
          json_name: "nested"
          number: 2
          type: TYPE_STRING
          extendee: ".MyMessage"
          options {
            features {
              [swift_feature_test.test] { feature4: ENUM_FEATURE_VALUE5 }
            }
          }
        }
      }
      extension {
        name: "top"
        json_name: "top"
        number: 1
        type: TYPE_STRING
        extendee: ".MyMessage"
        options {
          features {
            [swift_feature_test.test] { feature2: ENUM_FEATURE_VALUE3 }
          }
        }
      }
      """)

    let topFeatures = context.file.extensions.first!.features
    XCTAssertTrue(topFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(topFeatures.SwiftFeatureTest_test.feature1, .value2)  // File override
    XCTAssertEqual(topFeatures.SwiftFeatureTest_test.feature2, .value3)  // "top" Extension override
    let nestedFeatures = context.file.messages.first!.extensions.first!.features
    XCTAssertTrue(nestedFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature1, .value2)  // File override
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature2, .value1)  // default ("top" Extension override)
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature3, .value4)  // Message override
    XCTAssertEqual(nestedFeatures.SwiftFeatureTest_test.feature4, .value5)  // "nested" Extension override
  }

  func testMessageFieldLevel_Defaults() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      message_type {
        name: "MyMessage"
        field {
          name: "field"
          json_name: "field"
          number: 1
          type: TYPE_STRING
        }
      }
      """)

    let features = context.file.messages.first!.fields.first!.features
    XCTAssertTrue(features.hasSwiftFeatureTest_test)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature2, .value1)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature3, .value1)
  }

  func testMessageFieldLevel_Override() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      options {
        features {
          [swift_feature_test.test] { feature1: ENUM_FEATURE_VALUE2 }
        }
      }
      message_type {
        name: "MyMessage"
        options {
          features {
            [swift_feature_test.test] { feature2: ENUM_FEATURE_VALUE3 }
          }
        }
        field {
          name: "field"
          json_name: "field"
          number: 1
          type: TYPE_STRING
          options {
            features {
              [swift_feature_test.test] { feature3: ENUM_FEATURE_VALUE4 }
            }
          }
        }
      }
      """)

    let features = context.file.messages.first!.fields.first!.features
    XCTAssertTrue(features.hasSwiftFeatureTest_test)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature1, .value2)  // File override
    XCTAssertEqual(features.SwiftFeatureTest_test.feature2, .value3)  // Message override
    XCTAssertEqual(features.SwiftFeatureTest_test.feature3, .value4)  // Field override
  }

  func testMessageOneofFieldLevel_Defaults() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      message_type {
        name: "MyMessage"
        oneof_decl { name: "my_oneof" }
        field {
          name: "oneof_field"
          json_name: "oneof_field"
          number: 1
          type: TYPE_STRING
          oneof_index: 0
        }
        field {
          name: "not_oneof_field"
          json_name: "not_oneof_field"
          number: 2
          type: TYPE_STRING
        }
      }
      """)

    let oneof = context.file.messages.first!.realOneofs.first!
    XCTAssertEqual(oneof.name, "my_oneof")
    let oneofFeatures = oneof.features
    XCTAssertTrue(oneofFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(oneofFeatures.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(oneofFeatures.SwiftFeatureTest_test.feature2, .value1)
    XCTAssertEqual(oneofFeatures.SwiftFeatureTest_test.feature3, .value1)
    let oneofField = context.file.messages.first!.fields.first!
    XCTAssertEqual(oneofField.name, "oneof_field")
    let oneofFieldFeatures = oneofField.features
    XCTAssertTrue(oneofFieldFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(oneofFieldFeatures.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(oneofFieldFeatures.SwiftFeatureTest_test.feature2, .value1)
    XCTAssertEqual(oneofFieldFeatures.SwiftFeatureTest_test.feature3, .value1)
    XCTAssertEqual(oneofFieldFeatures.SwiftFeatureTest_test.feature4, .value1)
    XCTAssertEqual(oneofFieldFeatures.SwiftFeatureTest_test.feature5, .value1)
    let field = context.file.messages.first!.fields[1]
    XCTAssertEqual(field.name, "not_oneof_field")
    let fieldFeatures = field.features
    XCTAssertTrue(fieldFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(fieldFeatures.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(fieldFeatures.SwiftFeatureTest_test.feature2, .value1)
    XCTAssertEqual(fieldFeatures.SwiftFeatureTest_test.feature3, .value1)
    XCTAssertEqual(fieldFeatures.SwiftFeatureTest_test.feature4, .value1)
    XCTAssertEqual(fieldFeatures.SwiftFeatureTest_test.feature5, .value1)
  }

  func testMessageOneofFieldLevel_Override() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      options {
        features {
          [swift_feature_test.test] { feature1: ENUM_FEATURE_VALUE2 }
        }
      }
      message_type {
        name: "MyMessage"
        options {
          features {
            [swift_feature_test.test] { feature2: ENUM_FEATURE_VALUE3 }
          }
        }
        oneof_decl {
          name: "my_oneof"
          options {
            features {
              [swift_feature_test.test] { feature3: ENUM_FEATURE_VALUE4 }
            }
          }
        }
        field {
          name: "oneof_field"
          json_name: "oneof_field"
          number: 1
          type: TYPE_STRING
          oneof_index: 0
          options {
            features {
              [swift_feature_test.test] { feature4: ENUM_FEATURE_VALUE5 }
            }
          }
        }
        field {
          name: "not_oneof_field"
          json_name: "not_oneof_field"
          number: 2
          type: TYPE_STRING
          options {
            features {
              [swift_feature_test.test] { feature5: ENUM_FEATURE_VALUE6 }
            }
          }
        }
      }
      """)

    let oneof = context.file.messages.first!.realOneofs.first!
    XCTAssertEqual(oneof.name, "my_oneof")
    let oneofFeatures = oneof.features
    XCTAssertTrue(oneofFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(oneofFeatures.SwiftFeatureTest_test.feature1, .value2)  // File override
    XCTAssertEqual(oneofFeatures.SwiftFeatureTest_test.feature2, .value3)  // Message override
    XCTAssertEqual(oneofFeatures.SwiftFeatureTest_test.feature3, .value4)  // Oneof override
    let oneofField = context.file.messages.first!.fields.first!
    XCTAssertEqual(oneofField.name, "oneof_field")
    let oneofFieldFeatures = oneofField.features
    XCTAssertTrue(oneofFieldFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(oneofFieldFeatures.SwiftFeatureTest_test.feature1, .value2)  // File override
    XCTAssertEqual(oneofFieldFeatures.SwiftFeatureTest_test.feature2, .value3)  // Message override
    XCTAssertEqual(oneofFieldFeatures.SwiftFeatureTest_test.feature3, .value4)  // Oneof override
    XCTAssertEqual(oneofFieldFeatures.SwiftFeatureTest_test.feature4, .value5)  // "oneof_field" Field override
    XCTAssertEqual(oneofFieldFeatures.SwiftFeatureTest_test.feature5, .value1)  // default ("not_oneof_field" Field override)
    let field = context.file.messages.first!.fields[1]
    XCTAssertEqual(field.name, "not_oneof_field")
    let fieldFeatures = field.features
    XCTAssertTrue(fieldFeatures.hasSwiftFeatureTest_test)
    XCTAssertEqual(fieldFeatures.SwiftFeatureTest_test.feature1, .value2)  // File override
    XCTAssertEqual(fieldFeatures.SwiftFeatureTest_test.feature2, .value3)  // Message override
    XCTAssertEqual(fieldFeatures.SwiftFeatureTest_test.feature3, .value1)  // default (Oneof override)
    XCTAssertEqual(fieldFeatures.SwiftFeatureTest_test.feature4, .value1)  // default ("oneof_field" Field override)
    XCTAssertEqual(fieldFeatures.SwiftFeatureTest_test.feature5, .value6)  // "not_oneof_field" Field override
  }

  func testServiceLevel_Defaults() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      service {
        name: "MyService"
      }
      """)

    let features = context.file.services.first!.features
    XCTAssertTrue(features.hasSwiftFeatureTest_test)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature2, .value1)
  }

  func testServiceLevel_Overrides() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      options {
        features {
          [swift_feature_test.test] { feature1: ENUM_FEATURE_VALUE3 }
        }
      }
      service {
        name: "MyService"
        options {
          features {
            [swift_feature_test.test] { feature2: ENUM_FEATURE_VALUE4 }
          }
        }
      }
      """)

    let features = context.file.services.first!.features
    XCTAssertTrue(features.hasSwiftFeatureTest_test)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature1, .value3)  // File override
    XCTAssertEqual(features.SwiftFeatureTest_test.feature2, .value4)  // Service override
  }

  func testMethodLevel_Defaults() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      message_type { name: "empty" }
      service {
        name: "MyService"
        method { name: "doSomething" input_type: ".empty" output_type: ".empty" }
      }
      """)

    let features = context.file.services.first!.methods.first!.features
    XCTAssertTrue(features.hasSwiftFeatureTest_test)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature1, .value1)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature2, .value1)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature3, .value1)
  }

  func testMethodLevel_Overrides() throws {
    let context = TestContext("""
      name: "test.proto"
      edition: EDITION_2023
      options {
        features {
          [swift_feature_test.test] { feature1: ENUM_FEATURE_VALUE3 }
        }
      }
      message_type { name: "empty" }
      service {
        name: "MyService"
        options {
          features {
            [swift_feature_test.test] { feature2: ENUM_FEATURE_VALUE4 }
          }
        }
        method {
          name: "doSomething"
          input_type: ".empty"
          output_type: ".empty"
          options {
            features {
              [swift_feature_test.test] { feature3: ENUM_FEATURE_VALUE5 }
            }
          }
        }
      }
      """)

    let features = context.file.services.first!.methods.first!.features
    XCTAssertTrue(features.hasSwiftFeatureTest_test)
    XCTAssertEqual(features.SwiftFeatureTest_test.feature1, .value3)  // File override
    XCTAssertEqual(features.SwiftFeatureTest_test.feature2, .value4)  // Service override
    XCTAssertEqual(features.SwiftFeatureTest_test.feature3, .value5)  // Method override
  }

}
