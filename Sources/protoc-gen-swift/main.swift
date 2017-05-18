// Sources/protoc-gen-swift/main.swift - Protoc plugin main
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
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
    let request = try CodeGeneratorRequest(serializedData: rawRequest)
    let context = try Context(request: request)
    response = context.generateResponse()
  } catch GenerationError.readFailure {
    response = CodeGeneratorResponse(error: "Failed to read the input")
  } catch GenerationError.unknownParameter(let name) {
    response = CodeGeneratorResponse(error: "Unknown generation parameter '\(name)'")
  } catch GenerationError.invalidParameterValue(let name, let value) {
    response = CodeGeneratorResponse(
      error: "Unknown value for generation parameter '\(name)': '\(value)'")
  } catch GenerationError.wrappedError(let message, let e) {
    response = CodeGeneratorResponse(error: "\(message): \(e)")
  } catch let e {
    response = CodeGeneratorResponse(error: "Internal Error: \(e)")
  }
  let serializedResponse = try response.serializedData()
  Stdout.write(bytes: serializedResponse)
} else {
  for f in filesToRead {
    let requestData = try readFileData(filename: f)
    Stderr.print("Read request: \(requestData.count) bytes from \(f)")
    let request = try CodeGeneratorRequest(serializedData: requestData)
    let context = try Context(request: request)
    let response = context.generateResponse()
    let content = response.file[0].content
    print(!content.isEmpty ? content : "<No content>")
  }
}
