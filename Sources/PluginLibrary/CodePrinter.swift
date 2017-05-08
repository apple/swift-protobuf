// Sources/PluginLibrary/CodePrinter.swift - Code output
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
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
  /// The string content that was printed.
  public private(set) var content = String()

  /// See if anything was printed.
  public var isEmpty: Bool { return content.isEmpty }

  /// The `UnicodeScalarView` representing a single indentation step.
  private let singleIndent: String.UnicodeScalarView

  /// The current indentation level (a collection of spaces).
  private var indentation = String.UnicodeScalarView()

  /// Keeps track of whether the printer is currently sitting at the beginning
  /// of a line.
  private var atLineStart = true

  public init(indent: String.UnicodeScalarView = "  ".unicodeScalars) {
    singleIndent = indent
  }

  /// Writes the given strings to the printer.
  ///
  /// - Parameter text: A variable-length list of strings to be printed.
  public mutating func print(_ text: String...) {
    for t in text {
      let scalars = t.unicodeScalars
      var index = scalars.startIndex
      let end = scalars.endIndex

      while index != end {
        let remainingSlice = scalars[index..<end]
        if let newLineIndex = remainingSlice.index(of: "\n") {
#if swift(>=3.1)
          // No correction needed.
#else
          // https://bugs.swift.org/browse/SR-1927
          // Work around this by finding the distance and computing the correct
          // index in `scalars`.
          let distance = remainingSlice.distance(from: remainingSlice.startIndex, to: newLineIndex)
          let newLineIndex = scalars.index(index, offsetBy: distance)
#endif
          if index != newLineIndex {
            // Only append indentation if the line isn't blank (i.e., there
            // aren't two adjacent newlines).
            if atLineStart {
              content.unicodeScalars.append(contentsOf: indentation)
            }
            content.unicodeScalars.append(
              contentsOf: scalars[index..<newLineIndex])
          }
          content.unicodeScalars.append("\n")

          atLineStart = true
          index = scalars.index(after: newLineIndex)
        } else {
          // We reached the end of the string, so just copy over whatever is
          // left.
          if atLineStart {
            content.unicodeScalars.append(contentsOf: indentation)
            atLineStart = false
          }
          content.unicodeScalars.append(contentsOf: remainingSlice)
          index = end
        }
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
