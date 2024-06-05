// Sources/Conformance/main.swift - Conformance test main
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Google's conformance test is a C++ program that pipes data to/from another
/// process.  The tester sends data to the test wrapper which encodes and decodes
/// data according to the provided instructions.  This allows a single test
/// scaffold to exercise many differnt implementations.
///
// -----------------------------------------------------------------------------

import Foundation

import SwiftProtobuf

extension FileHandle {
  fileprivate func _read(count: Int) -> Data? {
    if #available(macOS 10.15.4, *) {
      do {
        guard let result = try read(upToCount: count),
              result.count == count else {
          return nil
        }
        return result
      } catch {
        return nil
      }
    } else {
      let result = readData(ofLength: count)
      guard result.count == count else {
        return nil
      }
      return result
    }
  }
}

func readRequest() -> Data? {
    let stdIn = FileHandle.standardInput
    guard let countLEData = stdIn._read(count: 4) else {
        return nil
    }
    let countLE: UInt32 = countLEData.withUnsafeBytes { rawBuffer in
        rawBuffer.loadUnaligned(as: UInt32.self)
    }
    let count = UInt32(littleEndian: countLE)
    guard count < Int.max,
          let result = stdIn._read(count: Int(count)) else {
        return nil
    }
    return result
}

func writeResponse(data: Data) {
    let count = UInt32(data.count)
    var countLE = count.littleEndian
    let countLEData = Data(bytes: &countLE, count: MemoryLayout.size(ofValue: countLE))
    let stdOut = FileHandle.standardOutput
    stdOut.write(countLEData)
    stdOut.write(data)
}

func buildResponse(serializedData: Data) -> Conformance_ConformanceResponse {
    var response = Conformance_ConformanceResponse()

    let request: Conformance_ConformanceRequest
    do {
        request = try Conformance_ConformanceRequest(serializedBytes: serializedData)
    } catch {
        response.runtimeError = "Failed to parse conformance request"
        return response
    }

    // Detect when something gets added to the conformance request that isn't
    // supported yet.
    guard request.unknownFields.data.isEmpty else {
        response.runtimeError =
            "ConformanceRequest had unknown fields; regenerate conformance.pb.swift and"
            + " see what support needs to be added."
        return response
    }

    switch request.testCategory {
    case .unspecifiedTest, .binaryTest, .jsonTest, .jsonIgnoreUnknownParsingTest, .textFormatTest:
        break  // known, nothing to do.
    case .jspbTest:
        response.skipped =
            "ConformanceRequest had a JSPB_TEST TestCategory; those aren't supposed to"
            + " happen with opensource."
        return response
    case .UNRECOGNIZED(let x):
        response.runtimeError =
          "ConformanceRequest had a new testCategory (\(x)); regenerate conformance.pb.swift"
          + " and see what support needs to be added."
        return response
    }

    let msgType: any SwiftProtobuf.Message.Type
    let extensions: any SwiftProtobuf.ExtensionMap
    switch request.messageType {
    case "":
        // Note: This case is here to cover using a old version of the conformance test
        // runner that don't know about this field, and it is thus implicit.
        fallthrough
    case ProtobufTestMessages_Proto3_TestAllTypesProto3.protoMessageName:
        msgType = ProtobufTestMessages_Proto3_TestAllTypesProto3.self
        extensions = SwiftProtobuf.SimpleExtensionMap()
    case ProtobufTestMessages_Proto2_TestAllTypesProto2.protoMessageName:
        msgType = ProtobufTestMessages_Proto2_TestAllTypesProto2.self
        extensions = ProtobufTestMessages_Proto2_TestMessagesProto2_Extensions
    case ProtobufTestMessages_Editions_TestAllTypesEdition2023.protoMessageName:
        msgType = ProtobufTestMessages_Editions_TestAllTypesEdition2023.self
        extensions = ProtobufTestMessages_Editions_TestMessagesEdition2023_Extensions
    case ProtobufTestMessages_Editions_Proto3_TestAllTypesProto3.protoMessageName:
        msgType = ProtobufTestMessages_Editions_Proto3_TestAllTypesProto3.self
        extensions = SwiftProtobuf.SimpleExtensionMap()
    case ProtobufTestMessages_Editions_Proto2_TestAllTypesProto2.protoMessageName:
        msgType = ProtobufTestMessages_Editions_Proto2_TestAllTypesProto2.self
        extensions = ProtobufTestMessages_Editions_Proto2_TestMessagesProto2Editions_Extensions
    default:
        response.runtimeError = "Unexpected message type: \(request.messageType)"
        return response
    }

    let testMessage: any SwiftProtobuf.Message
    switch request.payload {
    case .protobufPayload(let data)?:
        do {
            testMessage = try msgType.init(serializedBytes: data, extensions: extensions)
        } catch let e {
            response.parseError = "Protobuf failed to parse: \(e)"
            return response
        }
    case .jsonPayload(let json)?:
        var options = JSONDecodingOptions()
        options.ignoreUnknownFields = (request.testCategory == .jsonIgnoreUnknownParsingTest)
        do {
            testMessage = try msgType.init(jsonString: json,
                                           extensions: extensions,
                                           options: options)
        } catch let e {
            response.parseError = "JSON failed to parse: \(e)"
            return response
        }
    case .jspbPayload(_)?:
        response.skipped =
            "ConformanceRequest had a jspb_payload ConformanceRequest payload; those aren't"
            + " supposed to happen with opensource."
        return response
    case .textPayload(let textFormat)?:
        do {
            testMessage = try msgType.init(textFormatString: textFormat, extensions: extensions)
        } catch let e {
            response.parseError = "TextFormat failed to parse: \(e)"
            return response
        }
    case nil:
        response.runtimeError = "No payload in request:\n\(request.textFormatString())"
        return response
    }

    switch request.requestedOutputFormat {
    case .protobuf:
        do {
            response.protobufPayload = try testMessage.serializedBytes()
        } catch let e {
            response.serializeError = "Failed to serialize: \(e)"
        }
    case .json:
        do {
            response.jsonPayload = try testMessage.jsonString()
        } catch let e {
            response.serializeError = "Failed to serialize: \(e)"
        }
    case .jspb:
        response.skipped =
            "ConformanceRequest had a requested_output_format of JSPB WireFormat; that"
            + " isn't supposed to happen with opensource."
    case .textFormat:
        var textFormatOptions = TextFormatEncodingOptions()
        textFormatOptions.printUnknownFields = request.printUnknownFields
        response.textPayload = testMessage.textFormatString(options: textFormatOptions)
    case .unspecified:
        response.runtimeError = "Request asked for the 'unspecified' result, that isn't valid."
    case .UNRECOGNIZED(let v):
        response.runtimeError = "Unknown output format: \(v)"
    }
    return response
}

func singleTest() throws -> Bool {
   if let indata = readRequest() {
       let response = buildResponse(serializedData: indata)
       let outdata: Data = try response.serializedData()
       writeResponse(data: outdata)
       return true
   } else {
       return false
   }
}

Google_Protobuf_Any.register(messageType: ProtobufTestMessages_Proto3_TestAllTypesProto3.self)
Google_Protobuf_Any.register(messageType: ProtobufTestMessages_Editions_Proto3_TestAllTypesProto3.self)

while try singleTest() {
}

