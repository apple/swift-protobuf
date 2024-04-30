import Foundation

import SwiftProtobuf

public enum FuzzOption<T: SupportsFuzzOptions> {
    case boolean(WritableKeyPath<T, Bool>)
    case byte(WritableKeyPath<T, Int>, mod: UInt8 = .max)
}

public protocol SupportsFuzzOptions {
    static var fuzzOptionsList: [FuzzOption<Self>] { get }
    init()
}

extension SupportsFuzzOptions {
    public static func extractOptions(
        _ start: UnsafeRawPointer,
        _ count: Int
    ) -> (Self, UnsafeRawBufferPointer)? {
        var start = start
        var count = count
        var options = Self()

        // No format can start with zero (invalid tag, not really UTF-8), so use that to
        // indicate there are decoding options. The one case that can start with a zero
        // would be length delimited binary, but since that's a zero length message, we
        // can go ahead and use that one also.
        guard count >= 2, start.loadUnaligned(as: UInt8.self) == 0 else {
            return (options, UnsafeRawBufferPointer(start: start, count: count))
        }

        // Set over the zero
        start += 1
        count -= 1

        var optionsBits: UInt8? = nil
        var bit = 0
        for opt in fuzzOptionsList {
            if optionsBits == nil {
                guard count >= 1 else {
                    return nil  // No data left to read bits
                }
                optionsBits = start.loadUnaligned(as: UInt8.self)
                start += 1
                count -= 1
            }

            let isSet = optionsBits! & (1 << bit) != 0
            switch opt {
            case .boolean(let keypath):
                options[keyPath: keypath] = isSet
            case .byte(let keypath, let mod):
                assert(mod >= 1 && mod <= UInt8.max)
                if isSet {
                    guard count >= 1 else {
                        return nil  // No more bytes to get a value, fail
                    }
                    let value = start.loadUnaligned(as: UInt8.self)
                    start += 1
                    count -= 1
                    options[keyPath: keypath] = Int(value % mod)
                }
            }

            bit += 1
            if bit == 8 {  // Rolled over, cause a new load next time through
                bit = 0
                optionsBits = nil
            }
        }
        // Ensure the any remaining bits are zero so they can be used in the future
        while optionsBits != nil && bit < 8 {
            if optionsBits! & (1 << bit) != 0 {
                return nil
            }
            bit += 1
        }

        return (options, UnsafeRawBufferPointer(start: start, count: count))
    }

}

extension BinaryDecodingOptions: SupportsFuzzOptions {
    public static var fuzzOptionsList: [FuzzOption<Self>] {
        return [
            // NOTE: Do not reorder these in the future as it invalidates all
            // existing cases.

            // The default depth is 100, so limit outselves to modding by 8 to
            // avoid allowing larger depths that could timeout.
            .byte(\.messageDepthLimit, mod: 8),
            .boolean(\.discardUnknownFields),
        ]
    }
}

extension JSONDecodingOptions: SupportsFuzzOptions {
    public static var fuzzOptionsList: [FuzzOption<Self>] {
        return [
            // NOTE: Do not reorder these in the future as it invalidates all
            // existing cases.

            // The default depth is 100, so limit outselves to modding by 8 to
            // avoid allowing larger depths that could timeout.
            .byte(\.messageDepthLimit, mod: 8),
            .boolean(\.ignoreUnknownFields),
        ]
    }
}

extension TextFormatDecodingOptions: SupportsFuzzOptions {
    public static var fuzzOptionsList: [FuzzOption<Self>] {
        return [
            // NOTE: Do not reorder these in the future as it invalidates all
            // existing cases.

            // The default depth is 100, so limit outselves to modding by 8 to
            // avoid allowing larger depths that could timeout.
            .byte(\.messageDepthLimit, mod: 8),
            .boolean(\.ignoreUnknownFields),
            .boolean(\.ignoreUnknownExtensionFields),
        ]
    }
}
