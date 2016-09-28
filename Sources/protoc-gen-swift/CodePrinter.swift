// Sources/CodePrinter.swift - Code output
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
/// This provides some basic indentation management for emitting structured
/// source code text.
///
// -----------------------------------------------------------------------------
import Foundation

struct CodePrinter {
    private(set) var content = ""
    private var currentIndentDepth = 0
    private var currentIndent = ""
    private var atLineStart = true

    mutating func print(_ text: String...) {
         for t in text {
            for c in t.characters {
                if c == "\n" {
                  content.append(c)
                  atLineStart = true
                } else {
                  if atLineStart {
                    content.append(currentIndent)
                    atLineStart = false
                  }
                  content.append(c)
                }
            }
         }
    }

    mutating private func resetIndent() {
        currentIndent = (0..<currentIndentDepth).map { Int -> String in return "  " } .joined(separator:"")
    }

    mutating func indent() {
        currentIndentDepth += 1
        resetIndent()
    }
    mutating func outdent() {
        currentIndentDepth -= 1
        resetIndent()
    }
}

