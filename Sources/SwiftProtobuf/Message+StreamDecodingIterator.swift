// Sources/SwiftProtobuf/Message+StreamDecodingIterator.swift - Iterator over binary delimited input streams
//
// Copyright (c) 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Message` to provide binary coding and decoding using ``Foundation/Data``.
///
// -----------------------------------------------------------------------------

import Foundation

extension Message {
  
  public static func streamDecodingIterator(inputStream: InputStream, bufferLength: Int = 32768) -> StreamDecodingIterator<Self> {
    return StreamDecodingIterator<Self>(inputStream: inputStream, bufferLength: bufferLength)
  }
}

/**
 Iterates over a binary-delimited protobuf input stream
 */
public struct StreamDecodingIterator<M: Message>: IteratorProtocol {
  
  fileprivate let buffer: ResizingBuffer
  
  public init(inputStream: InputStream, bufferLength: Int = 32768) {
    buffer = ResizingBuffer(inputStream: inputStream, bufferLength: bufferLength)
  }
  
  public func next() -> M? {
    do {
      let messageLength = try decodeVarint()
      if (messageLength == 0) {
        return nil
      }
      var message = M()
      let data = try buffer.read(for: Int(messageLength))
      try message.merge(serializedData: data)
      return message
    } catch {
      print(error)
      return nil
    }
  }
  
  //Adapted from SwiftProtobuf BinaryDecoder
  private func decodeVarint() throws -> UInt64 {
    let slice = try buffer.read(for: 1)
    if (slice.isEmpty) {
      return 0
    }
    var c = slice[slice.startIndex]
    if c & 0x80 == 0 {
      return UInt64(c)
    }
    var value = UInt64(c & 0x7f)
    var shift = UInt64(7)
    while true {
      if shift > 63 {
        throw BinaryDecodingError.malformedProtobuf
      }
      let slice = try buffer.read(for: 1)
      c = slice[slice.startIndex]
      value |= UInt64(c & 0x7f) << shift
      if c & 0x80 == 0 {
        return value
      }
      shift += 7
    }
  }
}

private class ResizingBuffer {
  
  let inputStream: InputStream
  let bufferLength: Int
  var pointer: Int = 0
  var buffer: [UInt8]
  var data: Data
  
  init(inputStream: InputStream, bufferLength: Int = 32768) {
    self.inputStream = inputStream
    self.bufferLength = bufferLength
    self.buffer = [UInt8](repeating: 0, count: bufferLength)
    let result = inputStream.read(&buffer, maxLength: buffer.count)
    self.data = Data(buffer.prefix(result))
  }
  
  /**
   Read the required data quantity from the buffer,
   loading more from the stream if necessary
   */
  func read(for nBytes: Int) throws -> Data {
    
    let end = pointer + nBytes
    
    if (end <= data.count) {
      let messageData = data[pointer..<end]
      pointer += nBytes
      return messageData
    } else {
      //more data may be required
      let prefix = data[pointer..<data.count]
      let remainingByteCount = nBytes - prefix.count
      
      var toLoad = bufferLength
      if (remainingByteCount > bufferLength) {
        let nPages = Int(ceil(Float(remainingByteCount) / Float(bufferLength)))
        toLoad = nPages * bufferLength
        self.buffer = [UInt8](repeating: 0, count: toLoad)
      }
      
      let result = inputStream.read(&buffer, maxLength: buffer.count)
      if result == 0 {
        return prefix
      } else if (result < 0) {
        throw inputStream.streamError ?? POSIXError(.EIO)
      }
      self.data = Data(buffer.prefix(result))
      
      let suffix = data[0..<remainingByteCount]
      pointer = remainingByteCount
      return prefix + suffix
    }
  }
}
