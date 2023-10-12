// Sources/SwiftProtobufPluginLibrary/StandardErrorOutputStream.swift
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//

import Foundation

class StandardErrorOutputStream: TextOutputStream {
  func write(_ string: String) {
    if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
      try! FileHandle.standardError.write(contentsOf: Data(string.utf8))
    } else {
      FileHandle.standardError.write(Data(string.utf8))
    }
  }
}
