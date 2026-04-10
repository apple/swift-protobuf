import SwiftProtobuf
import Testing
import protoc_gen_swift

extension Compression {
    static func decompress(_ compressed: [UInt8]) -> [UInt8] {
        compressed.withUnsafeBytes { buf in
            decompress(buf)
        }
    }
}

@Test func roundTrip() throws {
    let input = "ABABABABA"
    let inputBytes = Array(input.utf8)

    let compressed = Compression.compress(inputBytes)

    // Check constraint: high bit not set
    for byte in compressed {
        #expect(byte & 0x80 == 0, "High bit set in byte \(byte)")
    }

    let decompressed = Compression.decompress(compressed)
    #expect(decompressed == inputBytes)
}

@Test func emptyInput() throws {
    let inputBytes: [UInt8] = []
    let compressed = Compression.compress(inputBytes)
    let decompressed = Compression.decompress(compressed)
    #expect(decompressed == inputBytes)
}

@Test func repetitiveInput() throws {
    let input = String(repeating: "A", count: 100)
    let inputBytes = Array(input.utf8)
    let compressed = Compression.compress(inputBytes)

    // Check constraint
    for byte in compressed {
        #expect(byte & 0x80 == 0)
    }

    let decompressed = Compression.decompress(compressed)
    #expect(decompressed == inputBytes)

    // It should be compressed
    #expect(compressed.count < inputBytes.count)
}

@Test func largeInput() throws {
    var inputBytes = [UInt8](repeating: 0, count: 10000)
    for i in 0..<10000 {
        inputBytes[i] = UInt8(i % 256)
    }

    let compressed = Compression.compress(inputBytes)

    for byte in compressed {
        #expect(byte & 0x80 == 0)
    }

    let decompressed = Compression.decompress(compressed)
    #expect(decompressed == inputBytes)
}
