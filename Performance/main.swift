// Performance/main.swift - Performance harness entry point
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
/// Entry point that creates the performance harness and runs it.
///
// -----------------------------------------------------------------------------

import Foundation

let args = CommandLine.arguments
let resultsFile = args.count > 1 ?
    FileHandle(forWritingAtPath: args[1]) : nil
resultsFile?.seekToEndOfFile()

let harness = Harness(resultsFile: resultsFile)
harness.run()

resultsFile?.closeFile()
