// Copyright (c) 2014 - 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf

public enum FuzzOption<T: SupportsFuzzOptions> {
    case boolean(WritableKeyPath<T, Bool>)
    case byte(WritableKeyPath<T, Int>, mod: UInt8 = .max)
    // This next one was only needed to add TextFormatEncodingOptions.printUnknownFields because it
    // defaults to `true` and the use of the option was added after we had saved existing regression
    // inputs. Since this options support ensures the unused values were zero, by adding it later we
    // end up needing to invert the value to ensure we will read saved values and get the same
    // options back.
    case invertedBoolean(WritableKeyPath<T, Bool>)
}

public protocol SupportsFuzzOptions {
    static var fuzzOptionsList: [FuzzOption<Self>] { get }
    init()
}

private let reportDecodeInfo = ProcessInfo.processInfo.environment["DUMP_DECODE_INFO"] == "1"

extension SupportsFuzzOptions {
    public static func extractOptions(
        _ start: UnsafeRawPointer?,
        _ count: Int
    ) -> (Self, UnsafeRawBufferPointer)? {
        guard count >= 0, start != nil || count == 0 else {
            return nil
        }
        let initialCount = count
        var count = count
        var options = Self()

        // No format can start with zero (invalid tag, not really UTF-8), so use that to
        // indicate there are decoding options. The one case that can start with a zero
        // would be length delimited binary, but since that's a zero length message, we
        // can go ahead and use that one also.
        guard count >= 2, var start = start, start.loadUnaligned(as: UInt8.self) == 0 else {
            if reportDecodeInfo {
                print("No options to decode")
            }
            return (options, UnsafeRawBufferPointer(start: start, count: count))
        }

        // Step over the zero
        start += 1
        count -= 1

        var optionsBits = start.loadUnaligned(as: UInt8.self)
        start += 1
        count -= 1
        var bit = 0
        for opt in fuzzOptionsList {
            var isSet = optionsBits & (1 << bit) != 0
            if bit == 7 {
                // About the use the last bit of this byte, to allow more options in
                // the future, use this bit to indicate reading another byte.
                guard isSet else {
                    // No continuation, just return whatever we got.
                    bit = 8
                    break
                }
                guard count >= 1 else {
                    if reportDecodeInfo {
                        print("Continuation options, but no more data, count as invalid.")
                    }
                    return nil  // No data left to read bits
                }
                optionsBits = start.loadUnaligned(as: UInt8.self)
                start += 1
                count -= 1
                bit = 0
                isSet = optionsBits & (1 << bit) != 0
            }

            switch opt {
            case .boolean(let keypath):
                options[keyPath: keypath] = isSet
            case .byte(let keypath, let mod):
                assert(mod >= 1 && mod <= UInt8.max)
                if isSet {
                    guard count >= 1 else {
                        if reportDecodeInfo {
                            print(".byte, but no more data to read, count as invalid.")
                        }
                        return nil  // No more bytes to get a value, fail
                    }
                    let value = start.loadUnaligned(as: UInt8.self)
                    start += 1
                    count -= 1
                    options[keyPath: keypath] = Int(value % mod)
                }
            case .invertedBoolean(let keypath):
                options[keyPath: keypath] = !isSet
            }
            bit += 1
        }
        // Ensure the any remaining bits are zero so they can be used in the future
        while bit < 8 {
            if optionsBits & (1 << bit) != 0 {
                if reportDecodeInfo {
                    print("Reserved options bit non zero, count as invalid.")
                }
                return nil
            }
            bit += 1
        }

        if reportDecodeInfo {
            print("\(initialCount - count) bytes consumed off front for options: \(options)")
        }
        return (options, UnsafeRawBufferPointer(start: start, count: count))
    }

}

public struct BinaryFuzzingOptions: SupportsFuzzOptions {
    public var decoding = BinaryDecodingOptions()
    public var encoding = BinaryEncodingOptions()

    public var allowPartial: Bool {
        get { decoding.allowPartial }
        set {
            decoding.allowPartial = newValue
            encoding.allowPartial = newValue
        }
    }

    public init() {}

    public static var fuzzOptionsList: [FuzzOption<Self>] {
        [
            // NOTE: Do not reorder these in the future as it invalidates all
            // existing cases.

            // The default depth is 100, so limit outselves to modding by 8 to
            // avoid allowing larger depths that could timeout.
            .byte(\.decoding.messageDepthLimit, mod: 8),
            .boolean(\.decoding.discardUnknownFields),
            .boolean(\.allowPartial),
            .boolean(\.encoding.useDeterministicOrdering),
        ]
    }
}

public struct JSONFuzzingOptions: SupportsFuzzOptions {
    public var decoding = JSONDecodingOptions()
    public var encoding = JSONEncodingOptions()

    public init() {
        encoding.extensions = SwiftProtoTesting_Fuzz_FuzzTesting_Extensions
    }

    public static var fuzzOptionsList: [FuzzOption<Self>] {
        [
            // NOTE: Do not reorder these in the future as it invalidates all
            // existing cases.

            // The default depth is 100, so limit outselves to modding by 8 to
            // avoid allowing larger depths that could timeout.
            .byte(\.decoding.messageDepthLimit, mod: 8),
            .boolean(\.decoding.ignoreUnknownFields),
            .boolean(\.encoding.alwaysPrintInt64sAsNumbers),
            .boolean(\.encoding.alwaysPrintEnumsAsInts),
            .boolean(\.encoding.preserveProtoFieldNames),
            .boolean(\.encoding.useDeterministicOrdering),
        ]
    }
}

public struct TextFormatFuzzingOptions: SupportsFuzzOptions {
    public var decoding = TextFormatDecodingOptions()
    public var encoding = TextFormatEncodingOptions()

    public init() {
        encoding.extensions = SwiftProtoTesting_Fuzz_FuzzTesting_Extensions
    }

    public static var fuzzOptionsList: [FuzzOption<Self>] {
        [
            // NOTE: Do not reorder these in the future as it invalidates all
            // existing cases.

            // The default depth is 100, so limit outselves to modding by 8 to
            // avoid allowing larger depths that could timeout.
            .byte(\.decoding.messageDepthLimit, mod: 8),
            .boolean(\.decoding.ignoreUnknownFields),
            .boolean(\.decoding.ignoreUnknownExtensionFields),
            .invertedBoolean(\.encoding.printUnknownFields),  // see note above for why inverted
            .invertedBoolean(\.encoding.useDeterministicOrdering),  // see note above for why inverted
        ]
    }
}
