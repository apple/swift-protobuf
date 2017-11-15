// Sources/SwiftProtobufPluginLibrary/FieldNumbers.swift - Proto Field numbers
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Field numbers needed by SwiftProtobufPluginLibrary since they currently aren't generated.
///
// -----------------------------------------------------------------------------

import Foundation

extension Google_Protobuf_FileDescriptorProto {
  struct FieldNumbers {
    static let messageType: Int32 = 4
    static let enumType: Int32 = 5
    static let service: Int32 = 6
    static let `extension`: Int32 = 7
  }
}

extension Google_Protobuf_DescriptorProto {
  struct FieldNumbers {
    static let field: Int32 = 2
    static let nestedType: Int32 = 3
    static let enumType: Int32 = 4
    static let `extension`: Int32 = 6
    static let oneofDecl: Int32 = 8
  }
}

extension Google_Protobuf_EnumDescriptorProto {
  struct FieldNumbers {
    static let value: Int32 = 2
  }
}

extension Google_Protobuf_ServiceDescriptorProto {
  struct FieldNumbers {
    static let method: Int32 = 2
  }
}
