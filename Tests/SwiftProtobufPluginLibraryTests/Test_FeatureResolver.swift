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
@testable import SwiftProtobufPluginLibrary

final class Test_FeatureResolver: XCTestCase {

  private func simpleResolver(extensions: [any AnyMessageExtension] = []) -> FeatureResolver {
    let defaults = try! Google_Protobuf_FeatureSetDefaults(textFormatString: """
      minimum_edition: EDITION_PROTO2
      maximum_edition: EDITION_2023
      defaults { edition: EDITION_2023 }
      """)
    return try! FeatureResolver(edition: .edition2023,
                                featureSetDefaults: defaults,
                                featureExtensions: extensions)
  }

  func testInit_EditionBelowMin() {
    let defaults = Google_Protobuf_FeatureSetDefaults.with {
      $0.minimumEdition = .proto3
      $0.maximumEdition = .edition2023
    }
    XCTAssertThrowsError(try FeatureResolver(edition: .proto2, featureSetDefaults: defaults)) { e in
      XCTAssertEqual(e as! FeatureResolver.Error,
                     FeatureResolver.Error.unsupported(edition: .proto2,
                                                       supported: Google_Protobuf_Edition.proto3...Google_Protobuf_Edition.edition2023))
    }
  }

  func testInit_EditionAboveMax() {
    let defaults = Google_Protobuf_FeatureSetDefaults.with {
      $0.minimumEdition = .proto2
      $0.maximumEdition = .proto3
    }
    XCTAssertThrowsError(try FeatureResolver(edition: .edition2023, featureSetDefaults: defaults)) { e in
      XCTAssertEqual(e as! FeatureResolver.Error,
                     FeatureResolver.Error.unsupported(edition: .edition2023,
                                                       supported: Google_Protobuf_Edition.proto2...Google_Protobuf_Edition.proto3))
    }
  }

  func testInit_EditionDefaultNotFound() {
    let defaults = try! Google_Protobuf_FeatureSetDefaults(textFormatString: """
      minimum_edition: EDITION_PROTO2
      maximum_edition: EDITION_2023
      defaults { edition: EDITION_2023 }
      """)
    XCTAssertThrowsError(try FeatureResolver(edition: .proto2, featureSetDefaults: defaults)) { e in
      XCTAssertEqual(e as! FeatureResolver.Error,
                     FeatureResolver.Error.noDefault(edition: .proto2))
    }
  }

  func testInit_EditionExactMatches() throws {
    let defaults = try! Google_Protobuf_FeatureSetDefaults(textFormatString: """
      minimum_edition: EDITION_99997_TEST_ONLY
      maximum_edition: EDITION_99999_TEST_ONLY
      defaults {
          edition: EDITION_99997_TEST_ONLY
          overridable_features { field_presence: EXPLICIT}
      }
      defaults {
          edition: EDITION_99998_TEST_ONLY
          overridable_features { field_presence: IMPLICIT}
      }
      defaults {
          edition: EDITION_99999_TEST_ONLY
          overridable_features { field_presence: LEGACY_REQUIRED}
      }
      """)

    // Ensure the right things were matched and we got the right feature sets.

    // If lookup fails, throw out of the test method.

    // edition99997TestOnly
    let resolver1: FeatureResolver = try FeatureResolver(edition: .edition99997TestOnly,
                                                         featureSetDefaults: defaults)
    XCTAssertEqual(resolver1.edition, .edition99997TestOnly)
    XCTAssertEqual(resolver1.defaultFeatureSet.fieldPresence, .explicit)

    // edition99998TestOnly
    let resolver2 = try FeatureResolver(edition: .edition99998TestOnly,
                                        featureSetDefaults: defaults)
    XCTAssertEqual(resolver2.edition, .edition99998TestOnly)
    XCTAssertEqual(resolver2.defaultFeatureSet.fieldPresence, .implicit)

    // edition99999TestOnly
    let resolver3 = try FeatureResolver(edition: .edition99999TestOnly,
                                        featureSetDefaults: defaults)
    XCTAssertEqual(resolver3.edition, .edition99999TestOnly)
    XCTAssertEqual(resolver3.defaultFeatureSet.fieldPresence, .legacyRequired)
  }

  func testInit_EditionMatchesLower() throws {
    let defaults = try! Google_Protobuf_FeatureSetDefaults(textFormatString: """
      minimum_edition: EDITION_99997_TEST_ONLY
      maximum_edition: EDITION_99999_TEST_ONLY
      defaults {
          edition: EDITION_99997_TEST_ONLY
          overridable_features { field_presence: EXPLICIT}
      }
      defaults {
          edition: EDITION_99999_TEST_ONLY
          overridable_features { field_presence: LEGACY_REQUIRED}
      }
      """)

    // Ensure the right things were matched and we got the right feature sets.

    // If lookup fails, throw out of the test method.

    // edition99997TestOnly
    let resolver1: FeatureResolver = try FeatureResolver(edition: .edition99997TestOnly,
                                                         featureSetDefaults: defaults)
    XCTAssertEqual(resolver1.edition, .edition99997TestOnly)
    XCTAssertEqual(resolver1.defaultFeatureSet.fieldPresence, .explicit)

    // edition99998TestOnly
    // The edition will says 99998 since that's what we requested, but the
    // defaults will have what was in 99997
    let resolver2 = try FeatureResolver(edition: .edition99998TestOnly,
                                        featureSetDefaults: defaults)
    XCTAssertEqual(resolver2.edition, .edition99998TestOnly)
    XCTAssertEqual(resolver2.defaultFeatureSet.fieldPresence, .explicit)

    // edition99999TestOnly
    let resolver3 = try FeatureResolver(edition: .edition99999TestOnly,
                                        featureSetDefaults: defaults)
    XCTAssertEqual(resolver3.edition, .edition99999TestOnly)
    XCTAssertEqual(resolver3.defaultFeatureSet.fieldPresence, .legacyRequired)
  }

  func testInit_BadExtension() throws {
    let defaults = try! Google_Protobuf_FeatureSetDefaults(textFormatString: """
      minimum_edition: EDITION_PROTO2
      maximum_edition: EDITION_2023
      defaults { edition: EDITION_PROTO2 }
      """)

    XCTAssertThrowsError(try FeatureResolver(edition: .proto2,
                                             featureSetDefaults: defaults,
                                             featureExtensions: [SwiftFeatureTest_Extensions_test,
                                                                 SDTExtensions_ext_str])) { e in
      XCTAssertEqual(e as! FeatureResolver.Error,
                     FeatureResolver.Error.invalidExtension(type: "google.protobuf.FieldOptions"))
    }
  }

  func testInit_mergingFixedOverridable() throws {
    let defaults = try! Google_Protobuf_FeatureSetDefaults(textFormatString: """
      minimum_edition: EDITION_99997_TEST_ONLY
      maximum_edition: EDITION_99999_TEST_ONLY
      defaults {
          edition: EDITION_99997_TEST_ONLY
          overridable_features { field_presence: EXPLICIT }
          fixed_features { enum_type: CLOSED }
      }
      """)

    // Test that fixed and overridable merge

    // If lookup fails, throw out of the test method.

    let resolver1: FeatureResolver = try FeatureResolver(edition: .edition99997TestOnly,
                                                         featureSetDefaults: defaults)
    XCTAssertEqual(resolver1.edition, .edition99997TestOnly)
    XCTAssertEqual(resolver1.defaultFeatureSet.fieldPresence, .explicit)
    XCTAssertEqual(resolver1.defaultFeatureSet.enumType, .closed)
  }

  func testResolve_Basics() {
    let resolver = simpleResolver()

    let features1 = Google_Protobuf_FeatureSet.with {
      $0.fieldPresence = .explicit
      $0.messageEncoding = .lengthPrefixed
    }
    let features2 = Google_Protobuf_FeatureSet.with {
      $0.enumType = .open
    }
    let features3 = Google_Protobuf_FeatureSet.with {
      $0.fieldPresence = .legacyRequired
      $0.jsonFormat = .legacyBestEffort
    }

    // No overlap
    let merged12 = resolver.resolve(features: features1, resolvedParent: features2)
    XCTAssertEqual(merged12.fieldPresence, .explicit)
    XCTAssertEqual(merged12.enumType, .open)
    XCTAssertEqual(merged12.messageEncoding, .lengthPrefixed)

    // Overlap, features overrides parent features
    let merged13 = resolver.resolve(features: features1, resolvedParent: features3)
    XCTAssertEqual(merged13.fieldPresence, .explicit)
    XCTAssertEqual(merged13.jsonFormat, .legacyBestEffort)
    XCTAssertEqual(merged13.messageEncoding, .lengthPrefixed)
  }

  func testResolve_CustomFeature() {
    let resolver = simpleResolver(extensions: [SwiftFeatureTest_Extensions_test])

    let features1 = Google_Protobuf_FeatureSet.with {
      $0.SwiftFeatureTest_test.feature1 = .value2
      $0.SwiftFeatureTest_test.feature2 = .value2
    }
    let features2 = Google_Protobuf_FeatureSet.with {
      $0.SwiftFeatureTest_test.feature3 = .value3
    }
    let features3 = Google_Protobuf_FeatureSet.with {
      $0.SwiftFeatureTest_test.feature1 = .value4
      $0.SwiftFeatureTest_test.feature3 = .value4
    }

    // No overlap
    let merged12 = resolver.resolve(features: features1, resolvedParent: features2)
    XCTAssertEqual(merged12.SwiftFeatureTest_test.feature1, .value2)
    XCTAssertEqual(merged12.SwiftFeatureTest_test.feature2, .value2)
    XCTAssertEqual(merged12.SwiftFeatureTest_test.feature3, .value3)

    // Overlap, features overrides parent features
    let merged13 = resolver.resolve(features: features1, resolvedParent: features3)
    XCTAssertEqual(merged13.SwiftFeatureTest_test.feature1, .value2)
    XCTAssertEqual(merged13.SwiftFeatureTest_test.feature2, .value2)
    XCTAssertEqual(merged13.SwiftFeatureTest_test.feature3, .value4)
  }
}
