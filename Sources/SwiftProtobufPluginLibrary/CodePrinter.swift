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

  private static let kNewline : String.UnicodeScalarView.Element = "\n"

  /// The string content that was printed.
  public var content: String {
    return String(contentScalars)
  }

  /// See if anything was printed.
  public var isEmpty: Bool { return contentScalars.isEmpty }

  /// The Unicode scalar buffer used to build up the printed contents.
  private var contentScalars = String.UnicodeScalarView()

  /// The `UnicodeScalarView` representing a single indentation step.
  private let singleIndent: String.UnicodeScalarView

  /// The current indentation level (a collection of spaces).
  private var indentation = String.UnicodeScalarView()

  /// Keeps track of whether the printer is currently sitting at the beginning
  /// of a line.
  private var atLineStart = true

  /// Initialize the printer to use the give indent.
  public init(indent: String.UnicodeScalarView = "  ".unicodeScalars) {
    contentScalars.reserveCapacity(CodePrinter.initialBufferSize)
    singleIndent = indent
  }

  /// Initialize a printer using the existing indention information from
  /// another CodePrinter.
  ///
  /// This is most useful to then use `append` to add the new content.
  public init(_ parent: Self) {
    self.init(indent: parent.singleIndent)
    indentation = parent.indentation
  }

  /// Writes the given strings to the printer.
  ///
  /// Newlines within the strings are honored and indentention is applied.
  ///
  /// - Parameter text: A variable-length list of strings to be printed.
  public mutating func print(_ text: String...) {
    for t in text {
      printInternal(t.unicodeScalars)
    }
  }

  /// Writes the given strings to the printer, adding a newline after
  /// each string. If called with no strings, a blank line is added to the
  /// printer.
  ///
  /// Newlines within the strings are honored and indentention is applied.
  ///
  /// - Parameter text: A variable-length list of strings to be printed.
  public mutating func println(_ text: String...) {
    if text.isEmpty {
      contentScalars.append(CodePrinter.kNewline)
      atLineStart = true
    } else {
      for t in text {
        printInternal(t.unicodeScalars)
        contentScalars.append(CodePrinter.kNewline)
        atLineStart = true
      }
    }
  }

  /// Indents, writes the given strings to the printer with a newline added
  /// to each one, and then outdents.
  ///
  /// Newlines within the strings are honored and indentention is applied.
  ///
  /// - Parameter text: A variable-length list of strings to be printed.
  public mutating func printlnIndented(_ text: String...) {
    indent()
    for t in text {
      printInternal(t.unicodeScalars)
      contentScalars.append(CodePrinter.kNewline)
      atLineStart = true
    }
    outdent()
  }

  private mutating func printInternal(_ scalars: String.UnicodeScalarView) {
    for scalar in scalars {
      // Indent at the start of a new line, unless it's a blank line.
      if atLineStart && scalar != CodePrinter.kNewline {
        contentScalars.append(contentsOf: indentation)
      }
      contentScalars.append(scalar)
      atLineStart = (scalar == CodePrinter.kNewline)
    }
  }

  /// Appended the content of another `CodePrinter`to this one.
  ///
  /// - Parameters:
  ///   - printer: The other `CodePrinter` to copy from.
  ///   - indenting: Boolean, if the text being appended should be reindented
  ///       to the current state of this printer. If the `printer` was
  ///       initialized off of this printer, there isn't a need to reindent.
  public mutating func append(_ printer: Self, indenting: Bool = false) {
    if indenting {
      printInternal(printer.contentScalars)
    } else {
      contentScalars.append(contentsOf: printer.contentScalars)
      atLineStart = printer.atLineStart
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

  /// Indents, calls `body` to do other work relaying along the printer, and
  /// the outdents after wards.
  ///
  /// - Parameter body: A closure that is invoked after the indent is
  ///     increasted.
  public mutating func withIndentation(body: (_ p: inout CodePrinter) -> Void) {
    indent()
    body(&self)
    outdent()
  }
}
