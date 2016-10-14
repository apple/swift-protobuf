// Sources/protoc-gen-swift/main.swift - Protoc plugin main
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// A protoc plugin is a code generator that accepts a protobuf-encoded
/// request on stdin and writes the protobuf-encoded response to stdout.
/// When protoc sees a command-line option of the form --foo_out=<path>,
/// it will run a program called `protoc-gen-foo` as the corresponding
/// plugin.
///
/// The request contains FileDescriptors with the parsed proto files
/// to be processed and some additional processing information.
///
// -----------------------------------------------------------------------------

import Foundation
import PluginLibrary

enum GenerationError: Error {
  /// Raised for any errors reading the input
  case readFailure
  /// Raise when parsing the parameter string and found an unknown key
  case unknownParameter(name: String)
}

func help(progname: String) {
  // The name we were invoked with
  print(progname + ": " + Version.summary)
  print("")
  // The internal name of the program (which may be different than we were invoked with)
  print(Version.versionedName)
  print(Version.copyright)
  print("")
  print(Version.help)
}

var filesToRead: [String] = []
var justVersion = false
var justHelp = false

//
// Crude command-line parser.
//
// Since this tool isn't ordinarily used directly, we don't
// need anything fancy here.  This is just for debugging.
//
var argIterator = CommandLine.arguments.makeIterator()
let programName = argIterator.next()
var nextArg = argIterator.next()
while let a = nextArg {
  switch a {
  case "-h":
    justHelp = true
  case "--version":
    justVersion = true
  default:
    if a.hasPrefix("-") {
      Stderr.print("Unknown argument \(a)")
      justHelp = true
    } else {
      filesToRead.append(a)
    }
  }
  nextArg = argIterator.next()
}

//
// Do something.
//

if justVersion {
  print(Version.versionedName)
} else if justHelp {
  help(progname: programName ?? Version.name)
} else if filesToRead.isEmpty {
  let response: CodeGeneratorResponse
  do {
    let rawRequest = try Stdin.readall()
    let request = try CodeGeneratorRequest(protobuf: rawRequest, extensions: SwiftOptions_Extensions)
    let context = try Context(request: request)
    response = context.generateResponse()
  } catch GenerationError.readFailure {
    response = CodeGeneratorResponse(error: "Failed to read the input")
  } catch GenerationError.unknownParameter(let name) {
    response = CodeGeneratorResponse(error: "Unknown generation parameter '\(name)'")
  } catch let e {
    response = CodeGeneratorResponse(error: "Internal Error: \(e)")
  }
  let serializedResponse = try response.serializeProtobuf()
  Stdout.write(bytes: serializedResponse)
} else {
  for f in filesToRead {
    let rawRequest = try readFileData(filename: f)
    Stderr.print("Read request: \(rawRequest.count) bytes from \(f)")
    let request = try CodeGeneratorRequest(protobuf: Data(bytes: rawRequest), extensions: SwiftOptions_Extensions)
    let context = try Context(request: request)
    let response = context.generateResponse()
    print(response.file[0].content ?? "<No content>")
  }
}
