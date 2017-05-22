// Sources/protoc-gen-swift/Version.swift - Protoc plugin version info
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A simple static object that provides information about the plugin.
///
// ----------------------------------------------------------------------------

import SwiftProtobuf

struct Version {
    // The "compatibility version" of the runtime library, which must be
    // incremented every time a breaking change (either behavioral or
    // API-changing) is introduced.
    //
    // We guarantee that generated protos that contain this version token will
    // be compatible with the runtime library containing the matching token.
    // Therefore, this number (and the corresponding one in the runtime
    // library) should not be updated for *every* version of Swift Protobuf,
    // but only for those that introduce breaking changes (either behavioral
    // or API-changing).
    static let compatibilityVersion = 2

    static let name = "protoc-gen-swift"
    static let versionedName = "protoc-gen-swift \(SwiftProtobuf.Version.versionString)"
    static let copyright = "Copyright (C) 2014-2017 Apple Inc. and the project authors"
    static let summary = "Convert parsed proto definitions into Swift"
    static let help = (
               "Note:  This is a plugin for protoc and should not normally be run\n"
               + "directly.\n"
               + "\n"
               + "If you invoke a recent version of protoc with the --swift_out=<dir>\n"
               + "option, then protoc will search the current PATH for protoc-gen-swift\n"
               + "and use it to generate Swift output.\n"
               + "\n"
               + "In particular, if you have renamed this program, you will need to\n"
               + "adjust the protoc command-line option accordingly.\n"
               + "\n"
               + "The generated Swift output requires the SwiftProtobuf \(SwiftProtobuf.Version.versionString)\n"
               + "library be included in your project.\n"
               + "\n"
               + "If you use `swift build` to compile your project, add this to\n"
               + "Package.swift:\n"
               + "\n"
               + "   dependencies: [\n"
               + "     .Package(url: \"https://github.com/apple/swift-protobuf-runtime.git\",\n"
               + "              Version(\(SwiftProtobuf.Version.versionString))\n"
               + "   ]\n"
               + "\n"
               + "\n"
               + "Usage: protoc-gen-swift [options] [filename...]\n"
               + "\n"
               + " -h:  Print this help message\n"
               + " --version: Print the program version\n"
               + "\n"
               + "Filenames specified on the command line indicate binary-encoded\n"
               + "google.protobuf.compiler.CodeGeneratorRequest objects that will\n"
               + "be read and converted to Swift source code.  The source text will be\n"
               + "written directly to stdout.\n"
               + "\n"
               + "When invoked with no filenames, it will read a single binary-encoded\n"
               + "google.protobuf.compiler.CodeGeneratorRequest object from stdin and\n"
               + "emit the corresponding CodeGeneratorResponse object to stdout.\n")
}
