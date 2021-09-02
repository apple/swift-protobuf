// Sources/SwiftProtobuf/Google_Protobuf_Duration+TextExtensions.swift - Extensions for Duration type
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extends the generated Duration struct with various custom behaviors:
/// * JSON coding and decoding
/// * Arithmetic operations
///
// -----------------------------------------------------------------------------

import Foundation

private let minDurationSeconds: Int64 = -maxDurationSeconds
private let maxDurationSeconds: Int64 = 315576000000

private func parseDuration(text: String) throws -> (Int64, Int32) {
  var digits = [Character]()
  var digitCount = 0
  var total = 0
  var chars = text.makeIterator()
  var seconds: Int64?
  var nanos: Int32 = 0
  while let c = chars.next() {
    switch c {
    case "-":
      // Only accept '-' as very first character
      if total > 0 {
        throw JSONDecodingError.malformedDuration
      }
      digits.append(c)
    case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
      digits.append(c)
      digitCount += 1
    case ".":
      if let _ = seconds {
        throw JSONDecodingError.malformedDuration
      }
      let digitString = String(digits)
      if let s = Int64(digitString),
        s >= minDurationSeconds && s <= maxDurationSeconds {
        seconds = s
      } else {
        throw JSONDecodingError.malformedDuration
      }
      digits.removeAll()
      digitCount = 0
    case "s":
      if let seconds = seconds {
        // Seconds already set, digits holds nanos
        while (digitCount < 9) {
          digits.append(Character("0"))
          digitCount += 1
        }
        while digitCount > 9 {
          digits.removeLast()
          digitCount -= 1
        }
        let digitString = String(digits)
        if let rawNanos = Int32(digitString) {
          if seconds < 0 {
            nanos = -rawNanos
          } else {
            nanos = rawNanos
          }
        } else {
          throw JSONDecodingError.malformedDuration
        }
      } else {
        // No fraction, we just have an integral number of seconds
        let digitString = String(digits)
        if let s = Int64(digitString),
          s >= minDurationSeconds && s <= maxDurationSeconds {
          seconds = s
        } else {
          throw JSONDecodingError.malformedDuration
        }
      }
      // Fail if there are characters after 's'
      if chars.next() != nil {
        throw JSONDecodingError.malformedDuration
      }
      return (seconds!, nanos)
    default:
      throw JSONDecodingError.malformedDuration
    }
    total += 1
  }
  throw JSONDecodingError.malformedDuration
}

private func formatDuration(seconds: Int64, nanos: Int32) -> String? {
  let (seconds, nanos) = normalizeForDuration(seconds: seconds, nanos: nanos)
  guard seconds >= minDurationSeconds && seconds <= maxDurationSeconds else {
    return nil
  }
  let nanosString = nanosToString(nanos: nanos) // Includes leading '.' if needed
  return "\(seconds)\(nanosString)s"
}

extension Google_Protobuf_Duration: _CustomJSONCodable {
  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    let s = try decoder.scanner.nextQuotedString()
    (seconds, nanos) = try parseDuration(text: s)
  }
  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    if let formatted = formatDuration(seconds: seconds, nanos: nanos) {
      return "\"\(formatted)\""
    } else {
      throw JSONEncodingError.durationRange
    }
  }
}

private func normalizeForDuration(
  seconds: Int64,
  nanos: Int32
) -> (seconds: Int64, nanos: Int32) {
  var s = seconds
  var n = nanos

  // If the magnitude of n exceeds a second then
  // we need to factor it into s instead.
  if n >= nanosPerSecond || n <= -nanosPerSecond {
    s += Int64(n / nanosPerSecond)
    n = n % nanosPerSecond
  }

  // The Duration spec says that when s != 0, s and
  // n must have the same sign.
  if s > 0 && n < 0 {
    n += nanosPerSecond
    s -= 1
  } else if s < 0 && n > 0 {
    n -= nanosPerSecond
    s += 1
  }

  return (seconds: s, nanos: n)
}
