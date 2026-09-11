// Sources/SwiftProtobufPluginLibrary/CodePrinter.swift - Code output
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// This provides some basic indentation management for emitting structured
// source code text.
//
// -----------------------------------------------------------------------------

/// Prints code with automatic indentation based on calls to indent and
/// outdent.
public struct CodePrinter {

    /// Reserve an initial buffer of 64KB scalars to eliminate some reallocations
    /// in smaller files.
    private static let initialBufferSize = 65536

    private static let kNewline: String.UnicodeScalarView.Element = "\n"

    /// The string content this printer has accumulated.
    public var content: String {
        String(contentScalars)
    }

    /// Whether this printer has printed anything yet.
    public var isEmpty: Bool { contentScalars.isEmpty }

    /// The Unicode scalar buffer the printer uses to build up its contents.
    private var contentScalars = String.UnicodeScalarView()

    /// The `UnicodeScalarView` representing a single indentation step.
    private let singleIndent: String.UnicodeScalarView

    /// The current indentation level (a collection of spaces).
    private var indentation = String.UnicodeScalarView()

    /// Keeps track of whether the printer is currently sitting at the beginning
    /// of a line.
    private var atLineStart = true

    /// Keeps track of whether the print APIs should add a newline after each
    /// string.
    private let newlines: Bool

    /// Creates a code printer that indents each level by the string you provide.
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
    /// but with control over whether the print APIs add newlines.
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

    /// Writes the strings you provide to the printer, adding a newline after each
    /// string.
    ///
    /// The printer honors newlines within the strings and applies indentation.
    ///
    /// The `addNewlines` value from initializing the printer controls whether
    /// the printer appends newlines after each string.
    ///
    /// Calling this with no strings adds a blank line to the printer (even if
    /// `addNewlines` was false when you initialized the printer).
    ///
    /// - Parameter text: A variable-length list of strings to print.
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

    /// Writes the strings you provide to the printer, optionally adding a newline
    /// after each string.
    ///
    /// Calling this with no strings adds a blank line to the printer.
    ///
    /// The printer honors newlines within the strings and applies indentation.
    ///
    /// - Parameters
    ///   - text: A variable-length list of strings to print.
    ///   - newlines: Boolean to control adding newlines after each string. This
    ///       is an explicit override of the `addNewlines` value using to
    ///       initialize this `CodePrinter`.
    public mutating func print(_ text: String..., newlines: Bool) {
        if text.isEmpty {
            assert(
                newlines,
                "Disabling newlines with no strings doesn't make sense."
            )
            contentScalars.append(CodePrinter.kNewline)
            atLineStart = true
        } else {
            for t in text {
                printInternal(t.unicodeScalars, addNewline: newlines)
            }
        }
    }

    /// Indents, writes the strings you provide to the printer, and then outdents.
    ///
    /// The printer honors newlines within the strings and applies indentation.
    ///
    /// The `addNewlines` value from initializing the printer controls whether
    /// the printer appends newlines after each string.
    ///
    /// - Parameter text: A variable-length list of strings to print.
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

    /// Appends the content of another printer to this one.
    ///
    /// - Parameters:
    ///   - printer: The other `CodePrinter` to copy from.
    ///   - indenting: Boolean; if true, this reindents the appended text to the
    ///       current state of this printer. If you initialized `printer`
    ///       from this printer, there isn't a need to reindent.
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

    /// Indents, calls body to do other work relaying along the printer, and
    /// then outdents.
    ///
    /// - Parameter body: A closure that runs after this increases the indent.
    public mutating func withIndentation(body: (_ p: inout CodePrinter) -> Void) {
        indent()
        body(&self)
        outdent()
    }
}
