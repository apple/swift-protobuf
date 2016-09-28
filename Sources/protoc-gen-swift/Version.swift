// Sources/Version.swift - Protoc plugin version info
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
/// A simple static object that provides information about the plugin.
///
// ----------------------------------------------------------------------------

struct Version {
    static let major = 0
    static let minor = 9
    static let revision = 22
    static let versionString = "\(major).\(minor).\(revision)"
    static let name = "protoc-gen-swift"
    static let versionedName = "protoc-gen-swift \(versionString)"
    static let copyright = "Copyright (C) 2014-2016 Apple Inc. and the Swift project authors"
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
               + "The generated Swift output requires the SwiftProtobuf \(versionString)\n"
               + "library be included in your project.\n"
               + "\n"
               + "If you use `swift build` to compiler your project, add this to\n"
               + "Package.swift:\n"
               + "\n"
               + "   dependencies: [\n"
               + "     .Package(url: \"https://github.com/apple/swift-protobuf-runtime.git\",\n"
               + "              Version(\(major),\(minor),\(revision))\n"
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
