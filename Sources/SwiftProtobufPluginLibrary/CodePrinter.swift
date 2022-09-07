// Sources/SwiftProtobufPluginLibrary/CodePrinter.swift - Code output
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This provides some basic indentation management for emitting structured
/// source code text.
///
// -----------------------------------------------------------------------------

/// Prints code with automatic indentation based on calls to `indent` and
/// `outdent`.
public struct CodePrinter {

  /// Reserve an initial buffer of 64KB scalars to eliminate some reallocations
  /// in smaller files.
  private static let initialBufferSize = 65536

  /// The string content that was printed.
  public var content: String {
    return String(contentScalars)
  }

  /// See if anything was printed.
  public var isEmpty: Bool { return content.isEmpty }

  /// The Unicode scalar buffer used to build up the printed contents.
  private var contentScalars = String.UnicodeScalarView()

  /// The `UnicodeScalarView` representing a single indentation step.
  private let singleIndent: String.UnicodeScalarView

  /// The current indentation level (a collection of spaces).
  private var indentation = String.UnicodeScalarView()

  /// Keeps track of whether the printer is currently sitting at the beginning
  /// of a line.
  private var atLineStart = true

  public init(indent: String.UnicodeScalarView = "  ".unicodeScalars) {
    contentScalars.reserveCapacity(CodePrinter.initialBufferSize)
    singleIndent = indent
  }

  /// Writes the given strings to the printer.
  ///
  /// Newlines within the strings are honored and indentention is applied.
  ///
  /// - Parameter text: A variable-length list of strings to be printed.
  public mutating func print(_ text: String...) {
    printInternal(text, false)
  }

  /// Indents, writes the given strings to the printer with a newline added
  /// to each one, and then outdents.
  ///
  /// Newlines within the strings are honored and indentention is applied.
  ///
  /// - Parameter text: A variable-length list of strings to be printed.
  public mutating func printlnIndented(_ text: String...) {
    indent()
    printInternal(text, true)
    outdent()
  }

  private static let kNewline : String.UnicodeScalarView.Element = "\n"

  private mutating func printInternal(_ text: [String], _ newline: Bool) {
    for t in text {
      for scalar in t.unicodeScalars {
        // Indent at the start of a new line, unless it's a blank line.
        if atLineStart && scalar != CodePrinter.kNewline {
          contentScalars.append(contentsOf: indentation)
        }
        contentScalars.append(scalar)
        atLineStart = (scalar == CodePrinter.kNewline)
      }
      if newline {
        contentScalars.append(CodePrinter.kNewline)
        atLineStart = true
      }
    }
  }
  /// Increases the printer's indentation level.
  public mutating func indent() {
    indentation.append(contentsOf: singleIndent)
  }

  /// Decreases the printer's indentation level.
  ///
  /// - Precondition: The printer must not have an indentation level.
  public mutating func outdent() {
    let indentCount = singleIndent.count
    precondition(indentation.count >= indentCount, "Cannot outdent past the left margin")
    indentation.removeLast(indentCount)
  }
}
