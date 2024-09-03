private import Foundation

struct InternalImportsByDefault {
    static func main() {
        let protoWithBytes = SomeProtoWithBytes.with { proto in
            proto.someBytes = Data()
            proto.extStr = ""
        }
        blackhole(protoWithBytes)
    }
}

@inline(never)
func blackhole<T>(_: T) {}
