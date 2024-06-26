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

  /// Keeps track of if a newline should be added after each string to the
  /// print apis.
  private let newlines: Bool

  public init(indent: String.UnicodeScalarView = "  ".unicodeScalars) {
    contentScalars.reserveCapacity(CodePrinter.initialBufferSize)
    singleIndent = indent
    newlines = false
  }

  /// Initialize the printer for use.
  ///
  /// - Parameters:
  ///   - indent: A string (usually spaces) to use for the indentation amount.
  ///   - newlines: A boolean indicating if every `print` and `printIndented`
  ///       should automatically add newlines to the end of the strings.
  public init(
    indent: String.UnicodeScalarView = "  ".unicodeScalars,
    addNewlines newlines: Bool
  ) {
    contentScalars.reserveCapacity(CodePrinter.initialBufferSize)
    singleIndent = indent
    self.newlines = newlines
  }

  /// Initialize a new printer using the existing state from another printer.
  ///
  /// This can be useful to use with generation subtasks, so see if they
  /// actually generate something (via `isEmpty`) to then optionally add it
  /// back into the parent with whatever surounding content.
  ///
  /// This is most useful to then use `append` to add the new content.
  ///
  /// - Parameter parent: The other printer to copy the configuration/state
  ///     from.
  public init(_ parent: CodePrinter) {
    self.init(parent, addNewlines: parent.newlines)
  }

  /// Initialize a new printer using the existing state from another printer
  /// but with support to control the behavior of `addNewlines`.
  ///
  /// This can be useful to use with generation subtasks, so see if they
  /// actually generate something (via `isEmpty`) to then optionally add it
  /// back into the parent with whatever surounding content.
  ///
  /// This is most useful to then use `append` to add the new content.
  ///
  /// - Parameters:
  ///   - parent: The other printer to copy the configuration/state
  ///       from.
  ///   - newlines: A boolean indicating if every `print` and `printIndented`
  ///       should automatically add newlines to the end of the strings.
  public init(_ parent: CodePrinter, addNewlines newlines: Bool) {
    self.init(indent: parent.singleIndent, addNewlines: newlines)
    indentation = parent.indentation
  }

  /// Writes the given strings to the printer, adding a newline after each
  /// string.
  ///
  /// Newlines within the strings are honored and indentention is applied.
  ///
  /// The `addNewlines` value from initializing the printer controls if
  /// newlines are appended after each string.
  ///
  /// If called with no strings, a blank line is added to the printer
  /// (even is `addNewlines` was false at initialization of the printer.
  ///
  /// - Parameter text: A variable-length list of strings to be printed.
  public mutating func print(_ text: String...) {
    if text.isEmpty {
      contentScalars.append(CodePrinter.kNewline)
      atLineStart = true
    } else {
      for t in text {
        printInternal(t.unicodeScalars, addNewline: newlines)
      }
    }
  }

  /// Writes the given strings to the printer, optionally adding a newline
  /// after each string. If called with no strings, a blank line is added to
  /// the printer.
  ///
  /// Newlines within the strings are honored and indentention is applied.
  ///
  /// - Parameters
  ///   - text: A variable-length list of strings to be printed.
  ///   - newlines: Boolean to control adding newlines after each string. This
  ///       is an explicit override of the `addNewlines` value using to
  ///       initialize this `CodePrinter`.
  public mutating func print(_ text: String..., newlines: Bool) {
    if text.isEmpty {
      assert(newlines,
             "Disabling newlines with no strings doesn't make sense.")
      contentScalars.append(CodePrinter.kNewline)
      atLineStart = true
    } else {
      for t in text {
        printInternal(t.unicodeScalars, addNewline: newlines)
      }
    }
  }

  /// Indents, writes the given strings to the printer, and then outdents.
  ///
  /// Newlines within the strings are honored and indentention is applied.
  ///
  /// The `addNewlines` value from initializing the printer controls if
  /// newlines are appended after each string.
  ///
  /// - Parameter text: A variable-length list of strings to be printed.
  public mutating func printIndented(_ text: String...) {
    indent()
    for t in text {
      printInternal(t.unicodeScalars, addNewline: newlines)
    }
    outdent()
  }

  private mutating func printInternal(
    _ scalars: String.UnicodeScalarView,
    addNewline: Bool
  ) {
    for scalar in scalars {
      // Indent at the start of a new line, unless it's a blank line.
      if atLineStart && scalar != CodePrinter.kNewline {
        contentScalars.append(contentsOf: indentation)
      }
      contentScalars.append(scalar)
      atLineStart = (scalar == CodePrinter.kNewline)
    }
    if addNewline {
      contentScalars.append(CodePrinter.kNewline)
      atLineStart = true
    }
  }

  /// Appended the content of another `CodePrinter`to this one.
  ///
  /// - Parameters:
  ///   - printer: The other `CodePrinter` to copy from.
  ///   - indenting: Boolean, if the text being appended should be reindented
  ///       to the current state of this printer. If the `printer` was
  ///       initialized off of this printer, there isn't a need to reindent.
  public mutating func append(_ printer: CodePrinter, indenting: Bool = false) {
    if indenting {
      printInternal(printer.contentScalars, addNewline: false)
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
