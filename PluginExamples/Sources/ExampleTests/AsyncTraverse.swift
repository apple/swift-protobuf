import AsyncTraverse
import SwiftProtobuf
import XCTest

final class AsyncTraverseTests: XCTestCase {
    func testAsyncTraverse() async throws {
        var message = AsyncTraverseMessage.with {
            $0.data = .init([UInt8(0)])
            $0.nested = .with {
                $0.data = .init([UInt8(1)])
                $0.nestedNested = .with {
                    $0.data = .init([UInt8(2)])
                }
            }
            $0.repeatedData = [.init([UInt8(3)]), .init([UInt8(4)])]
            $0.repeatedNested = [
                .with {
                    $0.data = .init([UInt8(5)])
                    $0.nestedNested = .with {
                        $0.data = .init([UInt8(6)])
                    }
                }
            ]
        }
        var visitor = MyVisitor()
        try await message.traverse(visitor: &visitor)
        XCTAssertEqual(message.data, .init([UInt8(1)]))
        XCTAssertEqual(message.nested.data, .init([UInt8(2)]))
        XCTAssertEqual(message.nested.nestedNested.data, .init([UInt8(3)]))
        XCTAssertEqual(message.repeatedData, [.init([UInt8(4)]), .init([UInt8(5)])])
        XCTAssertEqual(message.repeatedNested[0].data, .init([UInt8(6)]))
        XCTAssertEqual(message.repeatedNested[0].nestedNested.data, .init([UInt8(7)]))
    }
}

struct MyVisitor: AsyncVisitor {
    mutating func visitSingularMessageField(value: inout some Message, fieldNumber: Int) async throws {
        try await value.traverse(visitor: &self)
    }

    mutating func visitRepeatedMessageField<M>(value: inout [M], fieldNumber: Int) async throws
    where M: SwiftProtobuf.Message {
        for index in value.indices {
            try await value[index].traverse(visitor: &self)
        }
    }

    mutating func visitSingularBytesField(value: inout Data, fieldNumber: Int) async throws {
        value = Data([value.first! + UInt8(1)])
    }
    mutating func visitRepeatedBytesField(value: inout [Data], fieldNumber: Int) async throws {
        value = value.map { Data([$0.first! + UInt8(1)]) }
    }
}
