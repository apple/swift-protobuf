//
// GENERATED FILE
// DO NOT EDIT
//

import XCTest
@testable import SwiftProtobufTests
@testable import PluginLibraryTests

private func run_test(test:() -> ()) throws {
    test()
}

private func run_test(test:() throws -> ()) throws {
    try test()
}



extension Test_Descriptor {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testParsing", {try run_test(test:($0 as! Test_Descriptor).testParsing)}),
            ("testLookup", {try run_test(test:($0 as! Test_Descriptor).testLookup)}),
            ("testParents", {try run_test(test:($0 as! Test_Descriptor).testParents)}),
            ("testFields", {try run_test(test:($0 as! Test_Descriptor).testFields)}),
            ("testExtensions", {try run_test(test:($0 as! Test_Descriptor).testExtensions)})
        ]
    }
}

extension Test_NamingUtils {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testTypePrefix", {try run_test(test:($0 as! Test_NamingUtils).testTypePrefix)}),
            ("testStrip_protoPrefix", {try run_test(test:($0 as! Test_NamingUtils).testStrip_protoPrefix)}),
            ("testSanitize_messageName", {try run_test(test:($0 as! Test_NamingUtils).testSanitize_messageName)}),
            ("testSanitize_enumName", {try run_test(test:($0 as! Test_NamingUtils).testSanitize_enumName)}),
            ("testSanitize_oneofName", {try run_test(test:($0 as! Test_NamingUtils).testSanitize_oneofName)}),
            ("testSanitize_fieldName", {try run_test(test:($0 as! Test_NamingUtils).testSanitize_fieldName)}),
            ("testSanitize_enumCaseName", {try run_test(test:($0 as! Test_NamingUtils).testSanitize_enumCaseName)}),
            ("testSanitize_messageScopedExtensionName", {try run_test(test:($0 as! Test_NamingUtils).testSanitize_messageScopedExtensionName)}),
            ("testToCamelCase", {try run_test(test:($0 as! Test_NamingUtils).testToCamelCase)})
        ]
    }
}

extension Test_ProtoFileToModuleMappings {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_Initialization", {try run_test(test:($0 as! Test_ProtoFileToModuleMappings).test_Initialization)}),
            ("test_Initialization_InvalidConfigs", {try run_test(test:($0 as! Test_ProtoFileToModuleMappings).test_Initialization_InvalidConfigs)}),
            ("test_moduleName_forFile", {try run_test(test:($0 as! Test_ProtoFileToModuleMappings).test_moduleName_forFile)}),
            ("test_neededModules_forFile", {try run_test(test:($0 as! Test_ProtoFileToModuleMappings).test_neededModules_forFile)})
        ]
    }
}

extension Test_SwiftLanguage {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testIsValidSwiftIdentifier", {try run_test(test:($0 as! Test_SwiftLanguage).testIsValidSwiftIdentifier)}),
            ("testIsNotValidSwiftIdentifier", {try run_test(test:($0 as! Test_SwiftLanguage).testIsNotValidSwiftIdentifier)})
        ]
    }
}

extension Test_AllTypes {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testEncoding_unknown", {try run_test(test:($0 as! Test_AllTypes).testEncoding_unknown)}),
            ("testEncoding_optionalInt32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalInt32)}),
            ("testEncoding_optionalInt64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalInt64)}),
            ("testEncoding_optionalUint32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalUint32)}),
            ("testEncoding_optionalUint64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalUint64)}),
            ("testEncoding_optionalSint32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalSint32)}),
            ("testEncoding_optionalSint64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalSint64)}),
            ("testEncoding_optionalFixed32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalFixed32)}),
            ("testEncoding_optionalFixed64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalFixed64)}),
            ("testEncoding_optionalSfixed32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalSfixed32)}),
            ("testEncoding_optionalSfixed64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalSfixed64)}),
            ("testEncoding_optionalFloat", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalFloat)}),
            ("testEncoding_optionalDouble", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalDouble)}),
            ("testEncoding_optionalBool", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalBool)}),
            ("testEncoding_optionalString", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalString)}),
            ("testEncoding_optionalGroup", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalGroup)}),
            ("testEncoding_optionalBytes", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalBytes)}),
            ("testEncoding_optionalNestedMessage", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalNestedMessage)}),
            ("testEncoding_optionalNestedMessage_unknown1", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalNestedMessage_unknown1)}),
            ("testEncoding_optionalNestedMessage_unknown2", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalNestedMessage_unknown2)}),
            ("testEncoding_optionalNestedMessage_unknown3", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalNestedMessage_unknown3)}),
            ("testEncoding_optionalNestedMessage_unknown4", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalNestedMessage_unknown4)}),
            ("testEncoding_optionalForeignMessage", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalForeignMessage)}),
            ("testEncoding_optionalImportMessage", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalImportMessage)}),
            ("testEncoding_optionalNestedEnum", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalNestedEnum)}),
            ("testEncoding_optionalForeignEnum", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalForeignEnum)}),
            ("testEncoding_optionalImportEnum", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalImportEnum)}),
            ("testEncoding_optionalStringPiece", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalStringPiece)}),
            ("testEncoding_optionalCord", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalCord)}),
            ("testEncoding_optionalPublicImportMessage", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalPublicImportMessage)}),
            ("testEncoding_optionalLazyMessage", {try run_test(test:($0 as! Test_AllTypes).testEncoding_optionalLazyMessage)}),
            ("testEncoding_repeatedInt32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedInt32)}),
            ("testEncoding_repeatedInt64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedInt64)}),
            ("testEncoding_repeatedUint32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedUint32)}),
            ("testEncoding_repeatedUint64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedUint64)}),
            ("testEncoding_repeatedSint32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedSint32)}),
            ("testEncoding_repeatedSint64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedSint64)}),
            ("testEncoding_repeatedFixed32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedFixed32)}),
            ("testEncoding_repeatedFixed64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedFixed64)}),
            ("testEncoding_repeatedSfixed32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedSfixed32)}),
            ("testEncoding_repeatedSfixed64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedSfixed64)}),
            ("testEncoding_repeatedFloat", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedFloat)}),
            ("testEncoding_repeatedDouble", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedDouble)}),
            ("testEncoding_repeatedBool", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedBool)}),
            ("testEncoding_repeatedString", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedString)}),
            ("testEncoding_repeatedBytes", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedBytes)}),
            ("testEncoding_repeatedGroup", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedGroup)}),
            ("testEncoding_repeatedNestedMessage", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedNestedMessage)}),
            ("testEncoding_repeatedNestedMessage_unknown", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedNestedMessage_unknown)}),
            ("testEncoding_repeatedNestedEnum", {try run_test(test:($0 as! Test_AllTypes).testEncoding_repeatedNestedEnum)}),
            ("testEncoding_defaultInt32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultInt32)}),
            ("testEncoding_defaultInt64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultInt64)}),
            ("testEncoding_defaultUint32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultUint32)}),
            ("testEncoding_defaultUint64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultUint64)}),
            ("testEncoding_defaultSint32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultSint32)}),
            ("testEncoding_defaultSint64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultSint64)}),
            ("testEncoding_defaultFixed32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultFixed32)}),
            ("testEncoding_defaultFixed64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultFixed64)}),
            ("testEncoding_defaultSfixed32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultSfixed32)}),
            ("testEncoding_defaultSfixed64", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultSfixed64)}),
            ("testEncoding_defaultFloat", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultFloat)}),
            ("testEncoding_defaultDouble", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultDouble)}),
            ("testEncoding_defaultBool", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultBool)}),
            ("testEncoding_defaultString", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultString)}),
            ("testEncoding_defaultBytes", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultBytes)}),
            ("testEncoding_defaultNestedEnum", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultNestedEnum)}),
            ("testEncoding_defaultForeignEnum", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultForeignEnum)}),
            ("testEncoding_defaultImportEnum", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultImportEnum)}),
            ("testEncoding_defaultStringPiece", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultStringPiece)}),
            ("testEncoding_defaultCord", {try run_test(test:($0 as! Test_AllTypes).testEncoding_defaultCord)}),
            ("testEncoding_oneofUint32", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofUint32)}),
            ("testEncoding_oneofNestedMessage", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofNestedMessage)}),
            ("testEncoding_oneofNestedMessage1", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofNestedMessage1)}),
            ("testEncoding_oneofNestedMessage2", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofNestedMessage2)}),
            ("testEncoding_oneofNestedMessage9", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofNestedMessage9)}),
            ("testEncoding_oneofString", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofString)}),
            ("testEncoding_oneofBytes", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofBytes)}),
            ("testEncoding_oneofBytes2", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofBytes2)}),
            ("testEncoding_oneofBytes3", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofBytes3)}),
            ("testEncoding_oneofBytes4", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofBytes4)}),
            ("testEncoding_oneofBytes5", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofBytes5)}),
            ("testEncoding_oneofBytes_failures", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofBytes_failures)}),
            ("testEncoding_oneofBytes_debugDescription", {try run_test(test:($0 as! Test_AllTypes).testEncoding_oneofBytes_debugDescription)}),
            ("testDebugDescription", {try run_test(test:($0 as! Test_AllTypes).testDebugDescription)}),
            ("testDebugDescription2", {try run_test(test:($0 as! Test_AllTypes).testDebugDescription2)}),
            ("testDebugDescription3", {try run_test(test:($0 as! Test_AllTypes).testDebugDescription3)}),
            ("testDebugDescription4", {try run_test(test:($0 as! Test_AllTypes).testDebugDescription4)}),
            ("testWithFactoryHelper", {try run_test(test:($0 as! Test_AllTypes).testWithFactoryHelper)}),
            ("testWithFactoryHelperRethrows", {try run_test(test:($0 as! Test_AllTypes).testWithFactoryHelperRethrows)}),
            ("testUnknownFields_Success", {try run_test(test:($0 as! Test_AllTypes).testUnknownFields_Success)}),
            ("testUnknownFields_Failures", {try run_test(test:($0 as! Test_AllTypes).testUnknownFields_Failures)})
        ]
    }
}

extension Test_AllTypes_Proto3 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testEncoding_singleInt32", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleInt32)}),
            ("testEncoding_singleInt64", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleInt64)}),
            ("testEncoding_singleUint32", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleUint32)}),
            ("testEncoding_singleUint64", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleUint64)}),
            ("testEncoding_singleSint32", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleSint32)}),
            ("testEncoding_singleSint64", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleSint64)}),
            ("testEncoding_singleFixed32", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleFixed32)}),
            ("testEncoding_singleFixed64", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleFixed64)}),
            ("testEncoding_singleSfixed32", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleSfixed32)}),
            ("testEncoding_singleSfixed64", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleSfixed64)}),
            ("testEncoding_singleFloat", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleFloat)}),
            ("testEncoding_singleDouble", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleDouble)}),
            ("testEncoding_singleBool", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleBool)}),
            ("testEncoding_singleString", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleString)}),
            ("testEncoding_singleBytes", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleBytes)}),
            ("testEncoding_singleNestedMessage", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleNestedMessage)}),
            ("testEncoding_singleForeignMessage", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleForeignMessage)}),
            ("testEncoding_singleImportMessage", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleImportMessage)}),
            ("testEncoding_singleNestedEnum", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleNestedEnum)}),
            ("testEncoding_singleForeignEnum", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleForeignEnum)}),
            ("testEncoding_singleImportEnum", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singleImportEnum)}),
            ("testEncoding_singlePublicImportMessage", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_singlePublicImportMessage)}),
            ("testEncoding_repeatedInt32", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedInt32)}),
            ("testEncoding_repeatedInt64", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedInt64)}),
            ("testEncoding_repeatedUint32", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedUint32)}),
            ("testEncoding_repeatedUint64", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedUint64)}),
            ("testEncoding_repeatedSint32", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedSint32)}),
            ("testEncoding_repeatedSint64", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedSint64)}),
            ("testEncoding_repeatedFixed32", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedFixed32)}),
            ("testEncoding_repeatedFixed64", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedFixed64)}),
            ("testEncoding_repeatedSfixed32", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedSfixed32)}),
            ("testEncoding_repeatedSfixed64", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedSfixed64)}),
            ("testEncoding_repeatedFloat", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedFloat)}),
            ("testEncoding_repeatedDouble", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedDouble)}),
            ("testEncoding_repeatedBool", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedBool)}),
            ("testEncoding_repeatedString", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedString)}),
            ("testEncoding_repeatedBytes", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedBytes)}),
            ("testEncoding_repeatedNestedMessage", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedNestedMessage)}),
            ("testEncoding_repeatedNestedEnum", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_repeatedNestedEnum)}),
            ("testEncoding_oneofUint32", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofUint32)}),
            ("testEncoding_oneofNestedMessage", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofNestedMessage)}),
            ("testEncoding_oneofNestedMessage1", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofNestedMessage1)}),
            ("testEncoding_oneofNestedMessage2", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofNestedMessage2)}),
            ("testEncoding_oneofNestedMessage9", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofNestedMessage9)}),
            ("testEncoding_oneofString", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofString)}),
            ("testEncoding_oneofBytes", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofBytes)}),
            ("testEncoding_oneofBytes2", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofBytes2)}),
            ("testEncoding_oneofBytes3", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofBytes3)}),
            ("testEncoding_oneofBytes4", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofBytes4)}),
            ("testEncoding_oneofBytes5", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofBytes5)}),
            ("testEncoding_oneofBytes_failures", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofBytes_failures)}),
            ("testEncoding_oneofBytes_debugDescription", {try run_test(test:($0 as! Test_AllTypes_Proto3).testEncoding_oneofBytes_debugDescription)}),
            ("testDebugDescription", {try run_test(test:($0 as! Test_AllTypes_Proto3).testDebugDescription)}),
            ("testDebugDescription2", {try run_test(test:($0 as! Test_AllTypes_Proto3).testDebugDescription2)}),
            ("testDebugDescription3", {try run_test(test:($0 as! Test_AllTypes_Proto3).testDebugDescription3)})
        ]
    }
}

extension Test_Any {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_Any", {try run_test(test:($0 as! Test_Any).test_Any)}),
            ("test_Any_different_prefix", {try run_test(test:($0 as! Test_Any).test_Any_different_prefix)}),
            ("test_Any_noprefix", {try run_test(test:($0 as! Test_Any).test_Any_noprefix)}),
            ("test_Any_shortesttype", {try run_test(test:($0 as! Test_Any).test_Any_shortesttype)}),
            ("test_Any_UserMessage", {try run_test(test:($0 as! Test_Any).test_Any_UserMessage)}),
            ("test_Any_UnknownUserMessage_JSON", {try run_test(test:($0 as! Test_Any).test_Any_UnknownUserMessage_JSON)}),
            ("test_Any_UnknownUserMessage_protobuf", {try run_test(test:($0 as! Test_Any).test_Any_UnknownUserMessage_protobuf)}),
            ("test_Any_Any", {try run_test(test:($0 as! Test_Any).test_Any_Any)}),
            ("test_Any_Duration_JSON_roundtrip", {try run_test(test:($0 as! Test_Any).test_Any_Duration_JSON_roundtrip)}),
            ("test_Any_Duration_transcode", {try run_test(test:($0 as! Test_Any).test_Any_Duration_transcode)}),
            ("test_Any_FieldMask_JSON_roundtrip", {try run_test(test:($0 as! Test_Any).test_Any_FieldMask_JSON_roundtrip)}),
            ("test_Any_FieldMask_transcode", {try run_test(test:($0 as! Test_Any).test_Any_FieldMask_transcode)}),
            ("test_Any_Int32Value_JSON_roundtrip", {try run_test(test:($0 as! Test_Any).test_Any_Int32Value_JSON_roundtrip)}),
            ("test_Any_Int32Value_transcode", {try run_test(test:($0 as! Test_Any).test_Any_Int32Value_transcode)}),
            ("test_Any_Struct_JSON_roundtrip", {try run_test(test:($0 as! Test_Any).test_Any_Struct_JSON_roundtrip)}),
            ("test_Any_Struct_transcode", {try run_test(test:($0 as! Test_Any).test_Any_Struct_transcode)}),
            ("test_Any_Timestamp_JSON_roundtrip", {try run_test(test:($0 as! Test_Any).test_Any_Timestamp_JSON_roundtrip)}),
            ("test_Any_Timestamp_transcode", {try run_test(test:($0 as! Test_Any).test_Any_Timestamp_transcode)}),
            ("test_Any_ListValue_JSON_roundtrip", {try run_test(test:($0 as! Test_Any).test_Any_ListValue_JSON_roundtrip)}),
            ("test_Any_ListValue_transcode", {try run_test(test:($0 as! Test_Any).test_Any_ListValue_transcode)}),
            ("test_Any_Value_struct_JSON_roundtrip", {try run_test(test:($0 as! Test_Any).test_Any_Value_struct_JSON_roundtrip)}),
            ("test_Any_Value_struct_transcode", {try run_test(test:($0 as! Test_Any).test_Any_Value_struct_transcode)}),
            ("test_Any_Value_int_JSON_roundtrip", {try run_test(test:($0 as! Test_Any).test_Any_Value_int_JSON_roundtrip)}),
            ("test_Any_Value_int_transcode", {try run_test(test:($0 as! Test_Any).test_Any_Value_int_transcode)}),
            ("test_Any_Value_string_JSON_roundtrip", {try run_test(test:($0 as! Test_Any).test_Any_Value_string_JSON_roundtrip)}),
            ("test_Any_Value_string_transcode", {try run_test(test:($0 as! Test_Any).test_Any_Value_string_transcode)}),
            ("test_Any_OddTypeURL_FromValue", {try run_test(test:($0 as! Test_Any).test_Any_OddTypeURL_FromValue)}),
            ("test_Any_OddTypeURL_FromMessage", {try run_test(test:($0 as! Test_Any).test_Any_OddTypeURL_FromMessage)}),
            ("test_IsA", {try run_test(test:($0 as! Test_Any).test_IsA)}),
            ("test_Any_Registery", {try run_test(test:($0 as! Test_Any).test_Any_Registery)})
        ]
    }
}

extension Test_Api {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testExists", {try run_test(test:($0 as! Test_Api).testExists)}),
            ("testInitializer", {try run_test(test:($0 as! Test_Api).testInitializer)})
        ]
    }
}

extension Test_BasicFields_Access_Proto2 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testOptionalInt32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalInt32)}),
            ("testOptionalInt64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalInt64)}),
            ("testOptionalUint32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalUint32)}),
            ("testOptionalUint64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalUint64)}),
            ("testOptionalSint32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalSint32)}),
            ("testOptionalSint64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalSint64)}),
            ("testOptionalFixed32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalFixed32)}),
            ("testOptionalFixed64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalFixed64)}),
            ("testOptionalSfixed32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalSfixed32)}),
            ("testOptionalSfixed64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalSfixed64)}),
            ("testOptionalFloat", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalFloat)}),
            ("testOptionalDouble", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalDouble)}),
            ("testOptionalBool", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalBool)}),
            ("testOptionalString", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalString)}),
            ("testOptionalBytes", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalBytes)}),
            ("testOptionalGroup", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalGroup)}),
            ("testOptionalNestedMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalNestedMessage)}),
            ("testOptionalForeignMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalForeignMessage)}),
            ("testOptionalImportMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalImportMessage)}),
            ("testOptionalNestedEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalNestedEnum)}),
            ("testOptionalForeignEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalForeignEnum)}),
            ("testOptionalImportEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalImportEnum)}),
            ("testOptionalStringPiece", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalStringPiece)}),
            ("testOptionalCord", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalCord)}),
            ("testOptionalPublicImportMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalPublicImportMessage)}),
            ("testOptionalLazyMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testOptionalLazyMessage)}),
            ("testDefaultInt32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultInt32)}),
            ("testDefaultInt64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultInt64)}),
            ("testDefaultUint32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultUint32)}),
            ("testDefaultUint64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultUint64)}),
            ("testDefaultSint32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultSint32)}),
            ("testDefaultSint64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultSint64)}),
            ("testDefaultFixed32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultFixed32)}),
            ("testDefaultFixed64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultFixed64)}),
            ("testDefaultSfixed32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultSfixed32)}),
            ("testDefaultSfixed64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultSfixed64)}),
            ("testDefaultFloat", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultFloat)}),
            ("testDefaultDouble", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultDouble)}),
            ("testDefaultBool", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultBool)}),
            ("testDefaultString", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultString)}),
            ("testDefaultBytes", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultBytes)}),
            ("testDefaultNestedEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultNestedEnum)}),
            ("testDefaultForeignEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultForeignEnum)}),
            ("testDefaultImportEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultImportEnum)}),
            ("testDefaultStringPiece", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultStringPiece)}),
            ("testDefaultCord", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testDefaultCord)}),
            ("testRepeatedInt32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedInt32)}),
            ("testRepeatedInt64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedInt64)}),
            ("testRepeatedUint32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedUint32)}),
            ("testRepeatedUint64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedUint64)}),
            ("testRepeatedSint32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedSint32)}),
            ("testRepeatedSint64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedSint64)}),
            ("testRepeatedFixed32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedFixed32)}),
            ("testRepeatedFixed64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedFixed64)}),
            ("testRepeatedSfixed32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedSfixed32)}),
            ("testRepeatedSfixed64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedSfixed64)}),
            ("testRepeatedFloat", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedFloat)}),
            ("testRepeatedDouble", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedDouble)}),
            ("testRepeatedBool", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedBool)}),
            ("testRepeatedString", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedString)}),
            ("testRepeatedBytes", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedBytes)}),
            ("testRepeatedGroup", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedGroup)}),
            ("testRepeatedNestedMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedNestedMessage)}),
            ("testRepeatedForeignMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedForeignMessage)}),
            ("testRepeatedImportMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedImportMessage)}),
            ("testRepeatedNestedEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedNestedEnum)}),
            ("testRepeatedForeignEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedForeignEnum)}),
            ("testRepeatedImportEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedImportEnum)}),
            ("testRepeatedStringPiece", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedStringPiece)}),
            ("testRepeatedCord", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedCord)}),
            ("testRepeatedLazyMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto2).testRepeatedLazyMessage)})
        ]
    }
}

extension Test_BasicFields_Access_Proto3 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testOptionalInt32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalInt32)}),
            ("testOptionalInt64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalInt64)}),
            ("testOptionalUint32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalUint32)}),
            ("testOptionalUint64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalUint64)}),
            ("testOptionalSint32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalSint32)}),
            ("testOptionalSint64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalSint64)}),
            ("testOptionalFixed32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalFixed32)}),
            ("testOptionalFixed64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalFixed64)}),
            ("testOptionalSfixed32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalSfixed32)}),
            ("testOptionalSfixed64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalSfixed64)}),
            ("testOptionalFloat", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalFloat)}),
            ("testOptionalDouble", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalDouble)}),
            ("testOptionalBool", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalBool)}),
            ("testOptionalString", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalString)}),
            ("testOptionalBytes", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalBytes)}),
            ("testOptionalNestedMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalNestedMessage)}),
            ("testOptionalForeignMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalForeignMessage)}),
            ("testOptionalImportMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalImportMessage)}),
            ("testOptionalNestedEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalNestedEnum)}),
            ("testOptionalForeignEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalForeignEnum)}),
            ("testOptionalImportEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalImportEnum)}),
            ("testOptionalPublicImportMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testOptionalPublicImportMessage)}),
            ("testRepeatedInt32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedInt32)}),
            ("testRepeatedInt64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedInt64)}),
            ("testRepeatedUint32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedUint32)}),
            ("testRepeatedUint64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedUint64)}),
            ("testRepeatedSint32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedSint32)}),
            ("testRepeatedSint64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedSint64)}),
            ("testRepeatedFixed32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedFixed32)}),
            ("testRepeatedFixed64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedFixed64)}),
            ("testRepeatedSfixed32", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedSfixed32)}),
            ("testRepeatedSfixed64", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedSfixed64)}),
            ("testRepeatedFloat", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedFloat)}),
            ("testRepeatedDouble", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedDouble)}),
            ("testRepeatedBool", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedBool)}),
            ("testRepeatedString", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedString)}),
            ("testRepeatedBytes", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedBytes)}),
            ("testRepeatedNestedMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedNestedMessage)}),
            ("testRepeatedForeignMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedForeignMessage)}),
            ("testRepeatedImportMessage", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedImportMessage)}),
            ("testRepeatedNestedEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedNestedEnum)}),
            ("testRepeatedForeignEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedForeignEnum)}),
            ("testRepeatedImportEnum", {try run_test(test:($0 as! Test_BasicFields_Access_Proto3).testRepeatedImportEnum)})
        ]
    }
}

extension Test_Conformance {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testFieldNaming", {try run_test(test:($0 as! Test_Conformance).testFieldNaming)}),
            ("testFieldNaming_protoNames", {try run_test(test:($0 as! Test_Conformance).testFieldNaming_protoNames)}),
            ("testFieldNaming_escapeInName", {try run_test(test:($0 as! Test_Conformance).testFieldNaming_escapeInName)}),
            ("testInt32_min_roundtrip", {try run_test(test:($0 as! Test_Conformance).testInt32_min_roundtrip)}),
            ("testInt32_toosmall", {try run_test(test:($0 as! Test_Conformance).testInt32_toosmall)}),
            ("testRepeatedBoolWrapper", {try run_test(test:($0 as! Test_Conformance).testRepeatedBoolWrapper)}),
            ("testString_badUnicodeEscape", {try run_test(test:($0 as! Test_Conformance).testString_badUnicodeEscape)}),
            ("testString_surrogates", {try run_test(test:($0 as! Test_Conformance).testString_surrogates)})
        ]
    }
}

extension Test_Duration {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testJSON_encode", {try run_test(test:($0 as! Test_Duration).testJSON_encode)}),
            ("testJSON_decode", {try run_test(test:($0 as! Test_Duration).testJSON_decode)}),
            ("testSerializationFailure", {try run_test(test:($0 as! Test_Duration).testSerializationFailure)}),
            ("testJSON_durationField", {try run_test(test:($0 as! Test_Duration).testJSON_durationField)}),
            ("testFieldMember", {try run_test(test:($0 as! Test_Duration).testFieldMember)}),
            ("testTranscode", {try run_test(test:($0 as! Test_Duration).testTranscode)}),
            ("testConformance", {try run_test(test:($0 as! Test_Duration).testConformance)}),
            ("testBasicArithmetic", {try run_test(test:($0 as! Test_Duration).testBasicArithmetic)}),
            ("testArithmeticNormalizes", {try run_test(test:($0 as! Test_Duration).testArithmeticNormalizes)}),
            ("testFloatLiteralConvertible", {try run_test(test:($0 as! Test_Duration).testFloatLiteralConvertible)}),
            ("testInitializationByTimeIntervals", {try run_test(test:($0 as! Test_Duration).testInitializationByTimeIntervals)}),
            ("testGetters", {try run_test(test:($0 as! Test_Duration).testGetters)})
        ]
    }
}

extension Test_Empty {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testExists", {try run_test(test:($0 as! Test_Empty).testExists)})
        ]
    }
}

extension Test_Enum {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testEqual", {try run_test(test:($0 as! Test_Enum).testEqual)}),
            ("testJSONsingular", {try run_test(test:($0 as! Test_Enum).testJSONsingular)}),
            ("testJSONrepeated", {try run_test(test:($0 as! Test_Enum).testJSONrepeated)}),
            ("testEnumPrefix", {try run_test(test:($0 as! Test_Enum).testEnumPrefix)}),
            ("testUnknownValues", {try run_test(test:($0 as! Test_Enum).testUnknownValues)})
        ]
    }
}

extension Test_EnumWithAliases {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testJSONEncodeUsesOriginalNames", {try run_test(test:($0 as! Test_EnumWithAliases).testJSONEncodeUsesOriginalNames)}),
            ("testJSONDecodeAcceptsAllNames", {try run_test(test:($0 as! Test_EnumWithAliases).testJSONDecodeAcceptsAllNames)}),
            ("testTextFormatEncodeUsesOriginalNames", {try run_test(test:($0 as! Test_EnumWithAliases).testTextFormatEncodeUsesOriginalNames)}),
            ("testTextFormatDecodeAcceptsAllNames", {try run_test(test:($0 as! Test_EnumWithAliases).testTextFormatDecodeAcceptsAllNames)})
        ]
    }
}

extension Test_Enum_Proto2 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testEqual", {try run_test(test:($0 as! Test_Enum_Proto2).testEqual)}),
            ("testUnknownIgnored", {try run_test(test:($0 as! Test_Enum_Proto2).testUnknownIgnored)}),
            ("testJSONsingular", {try run_test(test:($0 as! Test_Enum_Proto2).testJSONsingular)}),
            ("testJSONrepeated", {try run_test(test:($0 as! Test_Enum_Proto2).testJSONrepeated)}),
            ("testEnumPrefix", {try run_test(test:($0 as! Test_Enum_Proto2).testEnumPrefix)}),
            ("testUnknownValues", {try run_test(test:($0 as! Test_Enum_Proto2).testUnknownValues)})
        ]
    }
}

extension Test_Extensions {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_optionalInt32Extension", {try run_test(test:($0 as! Test_Extensions).test_optionalInt32Extension)}),
            ("test_extensionMessageSpecificity", {try run_test(test:($0 as! Test_Extensions).test_extensionMessageSpecificity)}),
            ("test_optionalStringExtension", {try run_test(test:($0 as! Test_Extensions).test_optionalStringExtension)}),
            ("test_repeatedInt32Extension", {try run_test(test:($0 as! Test_Extensions).test_repeatedInt32Extension)}),
            ("test_defaultInt32Extension", {try run_test(test:($0 as! Test_Extensions).test_defaultInt32Extension)}),
            ("test_groupExtension", {try run_test(test:($0 as! Test_Extensions).test_groupExtension)}),
            ("test_repeatedGroupExtension", {try run_test(test:($0 as! Test_Extensions).test_repeatedGroupExtension)}),
            ("test_MessageNoStorageClass", {try run_test(test:($0 as! Test_Extensions).test_MessageNoStorageClass)}),
            ("test_MessageUsingStorageClass", {try run_test(test:($0 as! Test_Extensions).test_MessageUsingStorageClass)})
        ]
    }
}

extension Test_ExtremeDefaultValues {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_escapedBytes", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_escapedBytes)}),
            ("test_largeUint32", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_largeUint32)}),
            ("test_largeUint64", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_largeUint64)}),
            ("test_smallInt32", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_smallInt32)}),
            ("test_smallInt64", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_smallInt64)}),
            ("test_reallySmallInt32", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_reallySmallInt32)}),
            ("test_reallySmallInt64", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_reallySmallInt64)}),
            ("test_utf8String", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_utf8String)}),
            ("test_zeroFloat", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_zeroFloat)}),
            ("test_oneFloat", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_oneFloat)}),
            ("test_smallFloat", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_smallFloat)}),
            ("test_negativeOneFloat", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_negativeOneFloat)}),
            ("test_negativeFloat", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_negativeFloat)}),
            ("test_largeFloat", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_largeFloat)}),
            ("test_smallNegativeFloat", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_smallNegativeFloat)}),
            ("test_infDouble", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_infDouble)}),
            ("test_negInfDouble", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_negInfDouble)}),
            ("test_nanDouble", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_nanDouble)}),
            ("test_infFloat", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_infFloat)}),
            ("test_negInfFloat", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_negInfFloat)}),
            ("test_nanFloat", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_nanFloat)}),
            ("test_cppTrigraph", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_cppTrigraph)}),
            ("test_stringWithZero", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_stringWithZero)}),
            ("test_bytesWithZero", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_bytesWithZero)}),
            ("test_stringPieceWithZero", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_stringPieceWithZero)}),
            ("test_cordWithZero", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_cordWithZero)}),
            ("test_replacementString", {try run_test(test:($0 as! Test_ExtremeDefaultValues).test_replacementString)})
        ]
    }
}

extension Test_FieldMask {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testJSON", {try run_test(test:($0 as! Test_FieldMask).testJSON)}),
            ("testProtobuf", {try run_test(test:($0 as! Test_FieldMask).testProtobuf)}),
            ("testDebugDescription", {try run_test(test:($0 as! Test_FieldMask).testDebugDescription)}),
            ("testConvenienceInits", {try run_test(test:($0 as! Test_FieldMask).testConvenienceInits)}),
            ("testJSON_field", {try run_test(test:($0 as! Test_FieldMask).testJSON_field)}),
            ("testSerializationFailure", {try run_test(test:($0 as! Test_FieldMask).testSerializationFailure)})
        ]
    }
}

extension Test_FieldOrdering {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_FieldOrdering", {try run_test(test:($0 as! Test_FieldOrdering).test_FieldOrdering)})
        ]
    }
}

extension Test_GroupWithinGroup {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testGroupWithGroup_Single", {try run_test(test:($0 as! Test_GroupWithinGroup).testGroupWithGroup_Single)}),
            ("testGroupWithGroup_Repeated", {try run_test(test:($0 as! Test_GroupWithinGroup).testGroupWithGroup_Repeated)})
        ]
    }
}

extension Test_JSON {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testMultipleFields", {try run_test(test:($0 as! Test_JSON).testMultipleFields)}),
            ("testSingleInt32", {try run_test(test:($0 as! Test_JSON).testSingleInt32)}),
            ("testSingleUInt32", {try run_test(test:($0 as! Test_JSON).testSingleUInt32)}),
            ("testSingleInt64", {try run_test(test:($0 as! Test_JSON).testSingleInt64)}),
            ("testSingleDouble", {try run_test(test:($0 as! Test_JSON).testSingleDouble)}),
            ("testSingleFloat", {try run_test(test:($0 as! Test_JSON).testSingleFloat)}),
            ("testSingleDouble_NaN", {try run_test(test:($0 as! Test_JSON).testSingleDouble_NaN)}),
            ("testSingleFloat_NaN", {try run_test(test:($0 as! Test_JSON).testSingleFloat_NaN)}),
            ("testSingleBool", {try run_test(test:($0 as! Test_JSON).testSingleBool)}),
            ("testSingleString", {try run_test(test:($0 as! Test_JSON).testSingleString)}),
            ("testSingleString_controlCharacters", {try run_test(test:($0 as! Test_JSON).testSingleString_controlCharacters)}),
            ("testSingleBytes", {try run_test(test:($0 as! Test_JSON).testSingleBytes)}),
            ("testSingleBytes2", {try run_test(test:($0 as! Test_JSON).testSingleBytes2)}),
            ("testSingleBytes_roundtrip", {try run_test(test:($0 as! Test_JSON).testSingleBytes_roundtrip)}),
            ("testSingleNestedMessage", {try run_test(test:($0 as! Test_JSON).testSingleNestedMessage)}),
            ("testSingleNestedEnum", {try run_test(test:($0 as! Test_JSON).testSingleNestedEnum)}),
            ("testRepeatedInt32", {try run_test(test:($0 as! Test_JSON).testRepeatedInt32)}),
            ("testRepeatedString", {try run_test(test:($0 as! Test_JSON).testRepeatedString)}),
            ("testRepeatedNestedMessage", {try run_test(test:($0 as! Test_JSON).testRepeatedNestedMessage)}),
            ("testOneof", {try run_test(test:($0 as! Test_JSON).testOneof)})
        ]
    }
}

extension Test_JSONPacked {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testPackedFloat", {try run_test(test:($0 as! Test_JSONPacked).testPackedFloat)}),
            ("testPackedDouble", {try run_test(test:($0 as! Test_JSONPacked).testPackedDouble)}),
            ("testPackedInt32", {try run_test(test:($0 as! Test_JSONPacked).testPackedInt32)}),
            ("testPackedInt64", {try run_test(test:($0 as! Test_JSONPacked).testPackedInt64)}),
            ("testPackedUInt32", {try run_test(test:($0 as! Test_JSONPacked).testPackedUInt32)}),
            ("testPackedUInt64", {try run_test(test:($0 as! Test_JSONPacked).testPackedUInt64)}),
            ("testPackedSInt32", {try run_test(test:($0 as! Test_JSONPacked).testPackedSInt32)}),
            ("testPackedSInt64", {try run_test(test:($0 as! Test_JSONPacked).testPackedSInt64)}),
            ("testPackedFixed32", {try run_test(test:($0 as! Test_JSONPacked).testPackedFixed32)}),
            ("testPackedFixed64", {try run_test(test:($0 as! Test_JSONPacked).testPackedFixed64)}),
            ("testPackedSFixed32", {try run_test(test:($0 as! Test_JSONPacked).testPackedSFixed32)}),
            ("testPackedSFixed64", {try run_test(test:($0 as! Test_JSONPacked).testPackedSFixed64)}),
            ("testPackedBool", {try run_test(test:($0 as! Test_JSONPacked).testPackedBool)})
        ]
    }
}

extension Test_JSONUnpacked {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testPackedInt32", {try run_test(test:($0 as! Test_JSONUnpacked).testPackedInt32)})
        ]
    }
}

extension Test_JSON_Array {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testTwoObjectsWithMultipleFields", {try run_test(test:($0 as! Test_JSON_Array).testTwoObjectsWithMultipleFields)}),
            ("testRepeatedNestedMessage", {try run_test(test:($0 as! Test_JSON_Array).testRepeatedNestedMessage)})
        ]
    }
}

extension Test_JSON_Conformance {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testNullSupport_regularTypes", {try run_test(test:($0 as! Test_JSON_Conformance).testNullSupport_regularTypes)}),
            ("testNullSupport_wellKnownTypes", {try run_test(test:($0 as! Test_JSON_Conformance).testNullSupport_wellKnownTypes)}),
            ("testNullSupport_Value", {try run_test(test:($0 as! Test_JSON_Conformance).testNullSupport_Value)}),
            ("testNullSupport_Repeated", {try run_test(test:($0 as! Test_JSON_Conformance).testNullSupport_Repeated)}),
            ("testNullSupport_RepeatedValue", {try run_test(test:($0 as! Test_JSON_Conformance).testNullSupport_RepeatedValue)}),
            ("testNullConformance", {try run_test(test:($0 as! Test_JSON_Conformance).testNullConformance)}),
            ("testValueList", {try run_test(test:($0 as! Test_JSON_Conformance).testValueList)}),
            ("testNestedAny", {try run_test(test:($0 as! Test_JSON_Conformance).testNestedAny)})
        ]
    }
}

extension Test_JSON_Group {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testOptionalGroup", {try run_test(test:($0 as! Test_JSON_Group).testOptionalGroup)}),
            ("testRepeatedGroup", {try run_test(test:($0 as! Test_JSON_Group).testRepeatedGroup)})
        ]
    }
}

extension Test_Map {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_mapInt32Int32", {try run_test(test:($0 as! Test_Map).test_mapInt32Int32)}),
            ("test_mapInt64Int64", {try run_test(test:($0 as! Test_Map).test_mapInt64Int64)}),
            ("test_mapUint32Uint32", {try run_test(test:($0 as! Test_Map).test_mapUint32Uint32)}),
            ("test_mapUint64Uint64", {try run_test(test:($0 as! Test_Map).test_mapUint64Uint64)}),
            ("test_mapSint32Sint32", {try run_test(test:($0 as! Test_Map).test_mapSint32Sint32)}),
            ("test_mapSint64Sint64", {try run_test(test:($0 as! Test_Map).test_mapSint64Sint64)}),
            ("test_mapFixed32Fixed32", {try run_test(test:($0 as! Test_Map).test_mapFixed32Fixed32)}),
            ("test_mapFixed64Fixed64", {try run_test(test:($0 as! Test_Map).test_mapFixed64Fixed64)}),
            ("test_mapSfixed32Sfixed32", {try run_test(test:($0 as! Test_Map).test_mapSfixed32Sfixed32)}),
            ("test_mapSfixed64Sfixed64", {try run_test(test:($0 as! Test_Map).test_mapSfixed64Sfixed64)}),
            ("test_mapInt32Float", {try run_test(test:($0 as! Test_Map).test_mapInt32Float)}),
            ("test_mapInt32Double", {try run_test(test:($0 as! Test_Map).test_mapInt32Double)}),
            ("test_mapBoolBool", {try run_test(test:($0 as! Test_Map).test_mapBoolBool)}),
            ("test_mapStringString", {try run_test(test:($0 as! Test_Map).test_mapStringString)}),
            ("test_mapInt32Bytes", {try run_test(test:($0 as! Test_Map).test_mapInt32Bytes)}),
            ("test_mapInt32Enum", {try run_test(test:($0 as! Test_Map).test_mapInt32Enum)}),
            ("test_mapInt32ForeignMessage", {try run_test(test:($0 as! Test_Map).test_mapInt32ForeignMessage)}),
            ("test_mapStringForeignMessage", {try run_test(test:($0 as! Test_Map).test_mapStringForeignMessage)}),
            ("test_mapEnumUnknowns_Proto2", {try run_test(test:($0 as! Test_Map).test_mapEnumUnknowns_Proto2)}),
            ("test_mapEnumUnknowns_Proto3", {try run_test(test:($0 as! Test_Map).test_mapEnumUnknowns_Proto3)})
        ]
    }
}

extension Test_MapFields_Access_Proto2 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testMapInt32Int32", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapInt32Int32)}),
            ("testMapInt64Int64", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapInt64Int64)}),
            ("testMapUint32Uint32", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapUint32Uint32)}),
            ("testMapUint64Uint64", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapUint64Uint64)}),
            ("testMapSint32Sint32", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapSint32Sint32)}),
            ("testMapSint64Sint64", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapSint64Sint64)}),
            ("testMapFixed32Fixed32", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapFixed32Fixed32)}),
            ("testMapFixed64Fixed64", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapFixed64Fixed64)}),
            ("testMapSfixed32Sfixed32", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapSfixed32Sfixed32)}),
            ("testMapSfixed64Sfixed64", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapSfixed64Sfixed64)}),
            ("testMapInt32Float", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapInt32Float)}),
            ("testMapInt32Double", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapInt32Double)}),
            ("testMapBoolBool", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapBoolBool)}),
            ("testMapStringString", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapStringString)}),
            ("testMapStringBytes", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapStringBytes)}),
            ("testMapStringMessage", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapStringMessage)}),
            ("testMapInt32Bytes", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapInt32Bytes)}),
            ("testMapInt32Enum", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapInt32Enum)}),
            ("testMapInt32Message", {try run_test(test:($0 as! Test_MapFields_Access_Proto2).testMapInt32Message)})
        ]
    }
}

extension Test_MapFields_Access_Proto3 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testMapInt32Int32", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapInt32Int32)}),
            ("testMapInt64Int64", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapInt64Int64)}),
            ("testMapUint32Uint32", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapUint32Uint32)}),
            ("testMapUint64Uint64", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapUint64Uint64)}),
            ("testMapSint32Sint32", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapSint32Sint32)}),
            ("testMapSint64Sint64", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapSint64Sint64)}),
            ("testMapFixed32Fixed32", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapFixed32Fixed32)}),
            ("testMapFixed64Fixed64", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapFixed64Fixed64)}),
            ("testMapSfixed32Sfixed32", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapSfixed32Sfixed32)}),
            ("testMapSfixed64Sfixed64", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapSfixed64Sfixed64)}),
            ("testMapInt32Float", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapInt32Float)}),
            ("testMapInt32Double", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapInt32Double)}),
            ("testMapBoolBool", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapBoolBool)}),
            ("testMapStringString", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapStringString)}),
            ("testMapStringBytes", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapStringBytes)}),
            ("testMapStringMessage", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapStringMessage)}),
            ("testMapInt32Bytes", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapInt32Bytes)}),
            ("testMapInt32Enum", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapInt32Enum)}),
            ("testMapInt32Message", {try run_test(test:($0 as! Test_MapFields_Access_Proto3).testMapInt32Message)})
        ]
    }
}

extension Test_Map_JSON {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testMapInt32Int32", {try run_test(test:($0 as! Test_Map_JSON).testMapInt32Int32)}),
            ("testMapStringString", {try run_test(test:($0 as! Test_Map_JSON).testMapStringString)}),
            ("testMapInt32Bytes", {try run_test(test:($0 as! Test_Map_JSON).testMapInt32Bytes)}),
            ("testMapInt32Enum", {try run_test(test:($0 as! Test_Map_JSON).testMapInt32Enum)}),
            ("testMapInt32Message", {try run_test(test:($0 as! Test_Map_JSON).testMapInt32Message)}),
            ("test_mapBoolBool", {try run_test(test:($0 as! Test_Map_JSON).test_mapBoolBool)})
        ]
    }
}

extension Test_Merge {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testMergeSimple", {try run_test(test:($0 as! Test_Merge).testMergeSimple)}),
            ("testMergePreservesValueSemantics", {try run_test(test:($0 as! Test_Merge).testMergePreservesValueSemantics)})
        ]
    }
}

extension Test_FieldNamingInitials {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testHidingFunctions", {try run_test(test:($0 as! Test_FieldNamingInitials).testHidingFunctions)}),
            ("testLowers", {try run_test(test:($0 as! Test_FieldNamingInitials).testLowers)}),
            ("testUppers", {try run_test(test:($0 as! Test_FieldNamingInitials).testUppers)}),
            ("testWordCase", {try run_test(test:($0 as! Test_FieldNamingInitials).testWordCase)})
        ]
    }
}

extension Test_ExtensionNamingInitials_MessageScoped {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testLowers", {try run_test(test:($0 as! Test_ExtensionNamingInitials_MessageScoped).testLowers)}),
            ("testUppers", {try run_test(test:($0 as! Test_ExtensionNamingInitials_MessageScoped).testUppers)}),
            ("testWordCase", {try run_test(test:($0 as! Test_ExtensionNamingInitials_MessageScoped).testWordCase)})
        ]
    }
}

extension Test_ExtensionNamingInitials_GlobalScoped {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testLowers", {try run_test(test:($0 as! Test_ExtensionNamingInitials_GlobalScoped).testLowers)}),
            ("testUppers", {try run_test(test:($0 as! Test_ExtensionNamingInitials_GlobalScoped).testUppers)}),
            ("testWordCase", {try run_test(test:($0 as! Test_ExtensionNamingInitials_GlobalScoped).testWordCase)})
        ]
    }
}

extension Test_ExtensionNamingInitials_GlobalScoped_NoPrefix {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testLowers", {try run_test(test:($0 as! Test_ExtensionNamingInitials_GlobalScoped_NoPrefix).testLowers)}),
            ("testUppers", {try run_test(test:($0 as! Test_ExtensionNamingInitials_GlobalScoped_NoPrefix).testUppers)}),
            ("testWordCase", {try run_test(test:($0 as! Test_ExtensionNamingInitials_GlobalScoped_NoPrefix).testWordCase)})
        ]
    }
}

extension Test_OneofFields_Access_Proto2 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testOneofInt32", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofInt32)}),
            ("testOneofInt64", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofInt64)}),
            ("testOneofUint32", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofUint32)}),
            ("testOneofUint64", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofUint64)}),
            ("testOneofSint32", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofSint32)}),
            ("testOneofSint64", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofSint64)}),
            ("testOneofFixed32", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofFixed32)}),
            ("testOneofFixed64", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofFixed64)}),
            ("testOneofSfixed32", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofSfixed32)}),
            ("testOneofSfixed64", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofSfixed64)}),
            ("testOneofFloat", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofFloat)}),
            ("testOneofDouble", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofDouble)}),
            ("testOneofBool", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofBool)}),
            ("testOneofString", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofString)}),
            ("testOneofBytes", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofBytes)}),
            ("testOneofGroup", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofGroup)}),
            ("testOneofMessage", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofMessage)}),
            ("testOneofEnum", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofEnum)}),
            ("testOneofOnlyOneSet", {try run_test(test:($0 as! Test_OneofFields_Access_Proto2).testOneofOnlyOneSet)})
        ]
    }
}

extension Test_OneofFields_Access_Proto3 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testOneofInt32", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofInt32)}),
            ("testOneofInt64", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofInt64)}),
            ("testOneofUint32", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofUint32)}),
            ("testOneofUint64", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofUint64)}),
            ("testOneofSint32", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofSint32)}),
            ("testOneofSint64", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofSint64)}),
            ("testOneofFixed32", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofFixed32)}),
            ("testOneofFixed64", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofFixed64)}),
            ("testOneofSfixed32", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofSfixed32)}),
            ("testOneofSfixed64", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofSfixed64)}),
            ("testOneofFloat", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofFloat)}),
            ("testOneofDouble", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofDouble)}),
            ("testOneofBool", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofBool)}),
            ("testOneofString", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofString)}),
            ("testOneofBytes", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofBytes)}),
            ("testOneofMessage", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofMessage)}),
            ("testOneofEnum", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofEnum)}),
            ("testOneofOnlyOneSet", {try run_test(test:($0 as! Test_OneofFields_Access_Proto3).testOneofOnlyOneSet)})
        ]
    }
}

extension Test_Packed {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testEncoding_packedInt32", {try run_test(test:($0 as! Test_Packed).testEncoding_packedInt32)}),
            ("testEncoding_packedInt64", {try run_test(test:($0 as! Test_Packed).testEncoding_packedInt64)}),
            ("testEncoding_packedUint32", {try run_test(test:($0 as! Test_Packed).testEncoding_packedUint32)}),
            ("testEncoding_packedUint64", {try run_test(test:($0 as! Test_Packed).testEncoding_packedUint64)}),
            ("testEncoding_packedSint32", {try run_test(test:($0 as! Test_Packed).testEncoding_packedSint32)}),
            ("testEncoding_packedSint64", {try run_test(test:($0 as! Test_Packed).testEncoding_packedSint64)}),
            ("testEncoding_packedFixed32", {try run_test(test:($0 as! Test_Packed).testEncoding_packedFixed32)}),
            ("testEncoding_packedFixed64", {try run_test(test:($0 as! Test_Packed).testEncoding_packedFixed64)}),
            ("testEncoding_packedSfixed32", {try run_test(test:($0 as! Test_Packed).testEncoding_packedSfixed32)}),
            ("testEncoding_packedSfixed64", {try run_test(test:($0 as! Test_Packed).testEncoding_packedSfixed64)}),
            ("testEncoding_packedFloat", {try run_test(test:($0 as! Test_Packed).testEncoding_packedFloat)}),
            ("testEncoding_packedDouble", {try run_test(test:($0 as! Test_Packed).testEncoding_packedDouble)}),
            ("testEncoding_packedBool", {try run_test(test:($0 as! Test_Packed).testEncoding_packedBool)}),
            ("testEncoding_packedEnum", {try run_test(test:($0 as! Test_Packed).testEncoding_packedEnum)})
        ]
    }
}

extension Test_ParsingMerge {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_Merge", {try run_test(test:($0 as! Test_ParsingMerge).test_Merge)}),
            ("test_Merge_Oneof", {try run_test(test:($0 as! Test_ParsingMerge).test_Merge_Oneof)})
        ]
    }
}

extension Test_ReallyLargeTagNumber {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_ReallyLargeTagNumber", {try run_test(test:($0 as! Test_ReallyLargeTagNumber).test_ReallyLargeTagNumber)})
        ]
    }
}

extension Test_RecursiveMap {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_RecursiveMap", {try run_test(test:($0 as! Test_RecursiveMap).test_RecursiveMap)})
        ]
    }
}

extension Test_Required {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_IsInitialized", {try run_test(test:($0 as! Test_Required).test_IsInitialized)}),
            ("test_OneOf_IsInitialized", {try run_test(test:($0 as! Test_Required).test_OneOf_IsInitialized)}),
            ("test_NestedInProto2_IsInitialized", {try run_test(test:($0 as! Test_Required).test_NestedInProto2_IsInitialized)}),
            ("test_NestedInProto3_IsInitialized", {try run_test(test:($0 as! Test_Required).test_NestedInProto3_IsInitialized)}),
            ("test_map_isInitialized", {try run_test(test:($0 as! Test_Required).test_map_isInitialized)}),
            ("test_Extensions_isInitialized", {try run_test(test:($0 as! Test_Required).test_Extensions_isInitialized)}),
            ("test_decodeRequired", {try run_test(test:($0 as! Test_Required).test_decodeRequired)}),
            ("test_encodeRequired", {try run_test(test:($0 as! Test_Required).test_encodeRequired)})
        ]
    }
}

extension Test_SmallRequired {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_decodeRequired", {try run_test(test:($0 as! Test_SmallRequired).test_decodeRequired)}),
            ("test_encodeRequired", {try run_test(test:($0 as! Test_SmallRequired).test_encodeRequired)})
        ]
    }
}

extension Test_Reserved {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testEnumNaming", {try run_test(test:($0 as! Test_Reserved).testEnumNaming)}),
            ("testMessageNames", {try run_test(test:($0 as! Test_Reserved).testMessageNames)}),
            ("testFieldNamesMatchingMetadata", {try run_test(test:($0 as! Test_Reserved).testFieldNamesMatchingMetadata)}),
            ("testExtensionNamesMatching", {try run_test(test:($0 as! Test_Reserved).testExtensionNamesMatching)})
        ]
    }
}

extension Test_Struct {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testStruct_pbencode", {try run_test(test:($0 as! Test_Struct).testStruct_pbencode)}),
            ("testStruct_pbdecode", {try run_test(test:($0 as! Test_Struct).testStruct_pbdecode)}),
            ("test_JSON", {try run_test(test:($0 as! Test_Struct).test_JSON)}),
            ("test_JSON_field", {try run_test(test:($0 as! Test_Struct).test_JSON_field)}),
            ("test_equality", {try run_test(test:($0 as! Test_Struct).test_equality)})
        ]
    }
}

extension Test_JSON_ListValue {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testProtobuf", {try run_test(test:($0 as! Test_JSON_ListValue).testProtobuf)}),
            ("testJSON", {try run_test(test:($0 as! Test_JSON_ListValue).testJSON)}),
            ("test_equality", {try run_test(test:($0 as! Test_JSON_ListValue).test_equality)})
        ]
    }
}

extension Test_Value {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testValue_empty", {try run_test(test:($0 as! Test_Value).testValue_empty)})
        ]
    }
}

extension Test_JSON_Value {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testValue_emptyShouldThrow", {try run_test(test:($0 as! Test_JSON_Value).testValue_emptyShouldThrow)}),
            ("testValue_null", {try run_test(test:($0 as! Test_JSON_Value).testValue_null)}),
            ("testValue_number", {try run_test(test:($0 as! Test_JSON_Value).testValue_number)}),
            ("testValue_string", {try run_test(test:($0 as! Test_JSON_Value).testValue_string)}),
            ("testValue_bool", {try run_test(test:($0 as! Test_JSON_Value).testValue_bool)}),
            ("testValue_struct", {try run_test(test:($0 as! Test_JSON_Value).testValue_struct)}),
            ("testValue_list", {try run_test(test:($0 as! Test_JSON_Value).testValue_list)}),
            ("testValue_complex", {try run_test(test:($0 as! Test_JSON_Value).testValue_complex)}),
            ("testStruct_conformance", {try run_test(test:($0 as! Test_JSON_Value).testStruct_conformance)}),
            ("testStruct_null", {try run_test(test:($0 as! Test_JSON_Value).testStruct_null)})
        ]
    }
}

extension Test_TextFormat_Map_proto3 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_Int32Int32", {try run_test(test:($0 as! Test_TextFormat_Map_proto3).test_Int32Int32)}),
            ("test_StringMessage", {try run_test(test:($0 as! Test_TextFormat_Map_proto3).test_StringMessage)})
        ]
    }
}

extension Test_TextFormat_Unknown {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_unknown_varint", {try run_test(test:($0 as! Test_TextFormat_Unknown).test_unknown_varint)}),
            ("test_unknown_fixed64", {try run_test(test:($0 as! Test_TextFormat_Unknown).test_unknown_fixed64)}),
            ("test_unknown_lengthDelimited_string", {try run_test(test:($0 as! Test_TextFormat_Unknown).test_unknown_lengthDelimited_string)}),
            ("test_unknown_lengthDelimited_message", {try run_test(test:($0 as! Test_TextFormat_Unknown).test_unknown_lengthDelimited_message)}),
            ("test_unknown_lengthDelimited_notmessage", {try run_test(test:($0 as! Test_TextFormat_Unknown).test_unknown_lengthDelimited_notmessage)}),
            ("test_unknown_lengthDelimited_nested_message", {try run_test(test:($0 as! Test_TextFormat_Unknown).test_unknown_lengthDelimited_nested_message)}),
            ("test_unknown_group", {try run_test(test:($0 as! Test_TextFormat_Unknown).test_unknown_group)}),
            ("test_unknown_nested_group", {try run_test(test:($0 as! Test_TextFormat_Unknown).test_unknown_nested_group)}),
            ("test_unknown_fixed32", {try run_test(test:($0 as! Test_TextFormat_Unknown).test_unknown_fixed32)})
        ]
    }
}

extension Test_TextFormat_WKT_proto3 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testAny", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testAny)}),
            ("testAny_verbose", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testAny_verbose)}),
            ("testApi", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testApi)}),
            ("testDuration", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testDuration)}),
            ("testEmpty", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testEmpty)}),
            ("testFieldMask", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testFieldMask)}),
            ("testStruct", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testStruct)}),
            ("testTimestamp", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testTimestamp)}),
            ("testType", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testType)}),
            ("testDoubleValue", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testDoubleValue)}),
            ("testFloatValue", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testFloatValue)}),
            ("testInt64Value", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testInt64Value)}),
            ("testUInt64Value", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testUInt64Value)}),
            ("testInt32Value", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testInt32Value)}),
            ("testUInt32Value", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testUInt32Value)}),
            ("testBoolValue", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testBoolValue)}),
            ("testStringValue", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testStringValue)}),
            ("testBytesValue", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testBytesValue)}),
            ("testValue", {try run_test(test:($0 as! Test_TextFormat_WKT_proto3).testValue)})
        ]
    }
}

extension Test_TextFormat_proto2 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_group", {try run_test(test:($0 as! Test_TextFormat_proto2).test_group)}),
            ("test_repeatedGroup", {try run_test(test:($0 as! Test_TextFormat_proto2).test_repeatedGroup)})
        ]
    }
}

extension Test_TextFormat_proto2_extensions {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("test_file_level_extension", {try run_test(test:($0 as! Test_TextFormat_proto2_extensions).test_file_level_extension)}),
            ("test_nested_extension", {try run_test(test:($0 as! Test_TextFormat_proto2_extensions).test_nested_extension)})
        ]
    }
}

extension Test_TextFormat_proto3 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testDecoding_comments", {try run_test(test:($0 as! Test_TextFormat_proto3).testDecoding_comments)}),
            ("testEncoding_singleInt32", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleInt32)}),
            ("testEncoding_singleInt64", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleInt64)}),
            ("testEncoding_singleUint32", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleUint32)}),
            ("testEncoding_singleUint64", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleUint64)}),
            ("testEncoding_singleSint32", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleSint32)}),
            ("testEncoding_singleSint64", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleSint64)}),
            ("testEncoding_singleFixed32", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleFixed32)}),
            ("testEncoding_singleFixed64", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleFixed64)}),
            ("testEncoding_singleSfixed32", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleSfixed32)}),
            ("testEncoding_singleSfixed64", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleSfixed64)}),
            ("testEncoding_singleFloat", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleFloat)}),
            ("testEncoding_singleDouble", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleDouble)}),
            ("testEncoding_singleBool", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleBool)}),
            ("testEncoding_singleString", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleString)}),
            ("testEncoding_singleString_controlCharacters", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleString_controlCharacters)}),
            ("testEncoding_singleString_UTF8", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleString_UTF8)}),
            ("testEncoding_singleBytes", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleBytes)}),
            ("testEncoding_singleBytes_roundtrip", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleBytes_roundtrip)}),
            ("testEncoding_singleNestedMessage", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleNestedMessage)}),
            ("testEncoding_singleForeignMessage", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleForeignMessage)}),
            ("testEncoding_singleImportMessage", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleImportMessage)}),
            ("testEncoding_singleNestedEnum", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleNestedEnum)}),
            ("testEncoding_singleForeignEnum", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleForeignEnum)}),
            ("testEncoding_singleImportEnum", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singleImportEnum)}),
            ("testEncoding_singlePublicImportMessage", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_singlePublicImportMessage)}),
            ("testEncoding_repeatedInt32", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedInt32)}),
            ("testEncoding_repeatedInt64", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedInt64)}),
            ("testEncoding_repeatedUint32", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedUint32)}),
            ("testEncoding_repeatedUint64", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedUint64)}),
            ("testEncoding_repeatedSint32", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedSint32)}),
            ("testEncoding_repeatedSint64", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedSint64)}),
            ("testEncoding_repeatedFixed32", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedFixed32)}),
            ("testEncoding_repeatedFixed64", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedFixed64)}),
            ("testEncoding_repeatedSfixed32", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedSfixed32)}),
            ("testEncoding_repeatedSfixed64", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedSfixed64)}),
            ("testEncoding_repeatedFloat", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedFloat)}),
            ("testEncoding_repeatedDouble", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedDouble)}),
            ("testEncoding_repeatedBool", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedBool)}),
            ("testEncoding_repeatedString", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedString)}),
            ("testEncoding_repeatedBytes", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedBytes)}),
            ("testEncoding_repeatedNestedMessage", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedNestedMessage)}),
            ("testEncoding_repeatedForeignMessage", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedForeignMessage)}),
            ("testEncoding_repeatedImportMessage", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedImportMessage)}),
            ("testEncoding_repeatedNestedEnum", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedNestedEnum)}),
            ("testEncoding_repeatedForeignEnum", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedForeignEnum)}),
            ("testEncoding_repeatedImportEnum", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedImportEnum)}),
            ("testEncoding_repeatedPublicImportMessage", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_repeatedPublicImportMessage)}),
            ("testEncoding_oneofUint32", {try run_test(test:($0 as! Test_TextFormat_proto3).testEncoding_oneofUint32)}),
            ("testInvalidToken", {try run_test(test:($0 as! Test_TextFormat_proto3).testInvalidToken)}),
            ("testInvalidFieldName", {try run_test(test:($0 as! Test_TextFormat_proto3).testInvalidFieldName)}),
            ("testInvalidCapitalization", {try run_test(test:($0 as! Test_TextFormat_proto3).testInvalidCapitalization)}),
            ("testExplicitDelimiters", {try run_test(test:($0 as! Test_TextFormat_proto3).testExplicitDelimiters)}),
            ("testMultipleFields", {try run_test(test:($0 as! Test_TextFormat_proto3).testMultipleFields)})
        ]
    }
}

extension Test_Timestamp {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testJSON", {try run_test(test:($0 as! Test_Timestamp).testJSON)}),
            ("testJSON_range", {try run_test(test:($0 as! Test_Timestamp).testJSON_range)}),
            ("testJSON_timezones", {try run_test(test:($0 as! Test_Timestamp).testJSON_timezones)}),
            ("testJSON_timestampField", {try run_test(test:($0 as! Test_Timestamp).testJSON_timestampField)}),
            ("testJSON_conformance", {try run_test(test:($0 as! Test_Timestamp).testJSON_conformance)}),
            ("testSerializationFailure", {try run_test(test:($0 as! Test_Timestamp).testSerializationFailure)}),
            ("testBasicArithmetic", {try run_test(test:($0 as! Test_Timestamp).testBasicArithmetic)}),
            ("testArithmeticNormalizes", {try run_test(test:($0 as! Test_Timestamp).testArithmeticNormalizes)}),
            ("testInitializationByTimestamps", {try run_test(test:($0 as! Test_Timestamp).testInitializationByTimestamps)}),
            ("testInitializationByReferenceTimestamp", {try run_test(test:($0 as! Test_Timestamp).testInitializationByReferenceTimestamp)}),
            ("testInitializationByDates", {try run_test(test:($0 as! Test_Timestamp).testInitializationByDates)}),
            ("testTimestampGetters", {try run_test(test:($0 as! Test_Timestamp).testTimestampGetters)})
        ]
    }
}

extension Test_Type {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testExists", {try run_test(test:($0 as! Test_Type).testExists)})
        ]
    }
}

extension Test_Unknown_proto2 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testBinaryPB", {try run_test(test:($0 as! Test_Unknown_proto2).testBinaryPB)}),
            ("testJSON", {try run_test(test:($0 as! Test_Unknown_proto2).testJSON)}),
            ("test_MessageNoStorageClass", {try run_test(test:($0 as! Test_Unknown_proto2).test_MessageNoStorageClass)}),
            ("test_MessageUsingStorageClass", {try run_test(test:($0 as! Test_Unknown_proto2).test_MessageUsingStorageClass)})
        ]
    }
}

extension Test_Unknown_proto3 {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testBinaryPB", {try run_test(test:($0 as! Test_Unknown_proto3).testBinaryPB)}),
            ("testJSON", {try run_test(test:($0 as! Test_Unknown_proto3).testJSON)}),
            ("test_MessageNoStorageClass", {try run_test(test:($0 as! Test_Unknown_proto3).test_MessageNoStorageClass)}),
            ("test_MessageUsingStorageClass", {try run_test(test:($0 as! Test_Unknown_proto3).test_MessageUsingStorageClass)})
        ]
    }
}

extension Test_Wrappers {
    static var allTests: [(String, (XCTestCase) throws -> ())] {
        return [
            ("testDoubleValue", {try run_test(test:($0 as! Test_Wrappers).testDoubleValue)}),
            ("testFloatValue", {try run_test(test:($0 as! Test_Wrappers).testFloatValue)}),
            ("testInt64Value", {try run_test(test:($0 as! Test_Wrappers).testInt64Value)}),
            ("testUInt64Value", {try run_test(test:($0 as! Test_Wrappers).testUInt64Value)}),
            ("testInt32Value", {try run_test(test:($0 as! Test_Wrappers).testInt32Value)}),
            ("testUInt32Value", {try run_test(test:($0 as! Test_Wrappers).testUInt32Value)}),
            ("testBoolValue", {try run_test(test:($0 as! Test_Wrappers).testBoolValue)}),
            ("testStringValue", {try run_test(test:($0 as! Test_Wrappers).testStringValue)}),
            ("testBytesValue", {try run_test(test:($0 as! Test_Wrappers).testBytesValue)})
        ]
    }
}

XCTMain(
    [
        (testCaseClass: Test_Descriptor.self, allTests: Test_Descriptor.allTests),
        (testCaseClass: Test_NamingUtils.self, allTests: Test_NamingUtils.allTests),
        (testCaseClass: Test_ProtoFileToModuleMappings.self, allTests: Test_ProtoFileToModuleMappings.allTests),
        (testCaseClass: Test_SwiftLanguage.self, allTests: Test_SwiftLanguage.allTests),
        (testCaseClass: Test_AllTypes.self, allTests: Test_AllTypes.allTests),
        (testCaseClass: Test_AllTypes_Proto3.self, allTests: Test_AllTypes_Proto3.allTests),
        (testCaseClass: Test_Any.self, allTests: Test_Any.allTests),
        (testCaseClass: Test_Api.self, allTests: Test_Api.allTests),
        (testCaseClass: Test_BasicFields_Access_Proto2.self, allTests: Test_BasicFields_Access_Proto2.allTests),
        (testCaseClass: Test_BasicFields_Access_Proto3.self, allTests: Test_BasicFields_Access_Proto3.allTests),
        (testCaseClass: Test_Conformance.self, allTests: Test_Conformance.allTests),
        (testCaseClass: Test_Duration.self, allTests: Test_Duration.allTests),
        (testCaseClass: Test_Empty.self, allTests: Test_Empty.allTests),
        (testCaseClass: Test_Enum.self, allTests: Test_Enum.allTests),
        (testCaseClass: Test_EnumWithAliases.self, allTests: Test_EnumWithAliases.allTests),
        (testCaseClass: Test_Enum_Proto2.self, allTests: Test_Enum_Proto2.allTests),
        (testCaseClass: Test_Extensions.self, allTests: Test_Extensions.allTests),
        (testCaseClass: Test_ExtremeDefaultValues.self, allTests: Test_ExtremeDefaultValues.allTests),
        (testCaseClass: Test_FieldMask.self, allTests: Test_FieldMask.allTests),
        (testCaseClass: Test_FieldOrdering.self, allTests: Test_FieldOrdering.allTests),
        (testCaseClass: Test_GroupWithinGroup.self, allTests: Test_GroupWithinGroup.allTests),
        (testCaseClass: Test_JSON.self, allTests: Test_JSON.allTests),
        (testCaseClass: Test_JSONPacked.self, allTests: Test_JSONPacked.allTests),
        (testCaseClass: Test_JSONUnpacked.self, allTests: Test_JSONUnpacked.allTests),
        (testCaseClass: Test_JSON_Array.self, allTests: Test_JSON_Array.allTests),
        (testCaseClass: Test_JSON_Conformance.self, allTests: Test_JSON_Conformance.allTests),
        (testCaseClass: Test_JSON_Group.self, allTests: Test_JSON_Group.allTests),
        (testCaseClass: Test_Map.self, allTests: Test_Map.allTests),
        (testCaseClass: Test_MapFields_Access_Proto2.self, allTests: Test_MapFields_Access_Proto2.allTests),
        (testCaseClass: Test_MapFields_Access_Proto3.self, allTests: Test_MapFields_Access_Proto3.allTests),
        (testCaseClass: Test_Map_JSON.self, allTests: Test_Map_JSON.allTests),
        (testCaseClass: Test_Merge.self, allTests: Test_Merge.allTests),
        (testCaseClass: Test_FieldNamingInitials.self, allTests: Test_FieldNamingInitials.allTests),
        (testCaseClass: Test_ExtensionNamingInitials_MessageScoped.self, allTests: Test_ExtensionNamingInitials_MessageScoped.allTests),
        (testCaseClass: Test_ExtensionNamingInitials_GlobalScoped.self, allTests: Test_ExtensionNamingInitials_GlobalScoped.allTests),
        (testCaseClass: Test_ExtensionNamingInitials_GlobalScoped_NoPrefix.self, allTests: Test_ExtensionNamingInitials_GlobalScoped_NoPrefix.allTests),
        (testCaseClass: Test_OneofFields_Access_Proto2.self, allTests: Test_OneofFields_Access_Proto2.allTests),
        (testCaseClass: Test_OneofFields_Access_Proto3.self, allTests: Test_OneofFields_Access_Proto3.allTests),
        (testCaseClass: Test_Packed.self, allTests: Test_Packed.allTests),
        (testCaseClass: Test_ParsingMerge.self, allTests: Test_ParsingMerge.allTests),
        (testCaseClass: Test_ReallyLargeTagNumber.self, allTests: Test_ReallyLargeTagNumber.allTests),
        (testCaseClass: Test_RecursiveMap.self, allTests: Test_RecursiveMap.allTests),
        (testCaseClass: Test_Required.self, allTests: Test_Required.allTests),
        (testCaseClass: Test_SmallRequired.self, allTests: Test_SmallRequired.allTests),
        (testCaseClass: Test_Reserved.self, allTests: Test_Reserved.allTests),
        (testCaseClass: Test_Struct.self, allTests: Test_Struct.allTests),
        (testCaseClass: Test_JSON_ListValue.self, allTests: Test_JSON_ListValue.allTests),
        (testCaseClass: Test_Value.self, allTests: Test_Value.allTests),
        (testCaseClass: Test_JSON_Value.self, allTests: Test_JSON_Value.allTests),
        (testCaseClass: Test_TextFormat_Map_proto3.self, allTests: Test_TextFormat_Map_proto3.allTests),
        (testCaseClass: Test_TextFormat_Unknown.self, allTests: Test_TextFormat_Unknown.allTests),
        (testCaseClass: Test_TextFormat_WKT_proto3.self, allTests: Test_TextFormat_WKT_proto3.allTests),
        (testCaseClass: Test_TextFormat_proto2.self, allTests: Test_TextFormat_proto2.allTests),
        (testCaseClass: Test_TextFormat_proto2_extensions.self, allTests: Test_TextFormat_proto2_extensions.allTests),
        (testCaseClass: Test_TextFormat_proto3.self, allTests: Test_TextFormat_proto3.allTests),
        (testCaseClass: Test_Timestamp.self, allTests: Test_Timestamp.allTests),
        (testCaseClass: Test_Type.self, allTests: Test_Type.allTests),
        (testCaseClass: Test_Unknown_proto2.self, allTests: Test_Unknown_proto2.allTests),
        (testCaseClass: Test_Unknown_proto3.self, allTests: Test_Unknown_proto3.allTests),
        (testCaseClass: Test_Wrappers.self, allTests: Test_Wrappers.allTests)
    ]
)
