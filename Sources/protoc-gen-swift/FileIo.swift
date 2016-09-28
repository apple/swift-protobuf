// Sources/FileIo.swift - File I/O utilities
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// Some basic utilities to handle writing to Stderr, Stdout, and reading/writing
/// blocks of data from/to a file on disk.
///
// -----------------------------------------------------------------------------
import Foundation

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

private let _write = write

private func printToFd(_ s: String, fd: Int32, appendNewLine: Bool = true) {
    // Write UTF-8 bytes
    let bytes: [UInt8] = [UInt8](s.utf8)
    bytes.withUnsafeBufferPointer { (bp: UnsafeBufferPointer<UInt8>) -> () in
        write(fd, bp.baseAddress, bp.count)
    }
    // Write trailing newline
    [UInt8(10)].withUnsafeBufferPointer { (bp: UnsafeBufferPointer<UInt8>) -> () in
        write(fd, bp.baseAddress, bp.count)
    }
}

let Stderr = _Stderr()

class _Stderr {
    private(set) var content = ""
    private var currentIndentDepth = 0
    private var currentIndent = ""
    private var atLineStart = true

    private func resetIndent() {
        currentIndent = (0..<currentIndentDepth).map { Int -> String in return "  " } .joined(separator:"")
    }

    func print(_ s: String) {
       let out = currentIndent + "protoc-gen-swift: " + s
       printToFd(out, fd: 2)
    }

    func enter(_ s: String) {
        currentIndentDepth += 1
        resetIndent()
        print(s)
    }

    func exit(_ s: String = "") {
        currentIndentDepth -= 1
        if currentIndentDepth < 0 {currentIndentDepth = 0}
        resetIndent()
        print(s)
    }
}

class Stdout {
    static func print(_ s: String) { printToFd(s, fd: 1) }
    static func write(bytes: Data) {
        bytes.withUnsafeBytes { (p: UnsafePointer<UInt8>) -> () in
            _ = _write(1, p, bytes.count)
        }
    }
}

class Stdin {
    static func readall() throws -> Data {
        let fd: Int32 = 0
        let buffSize = 32
        var buff = [UInt8]()
        while true {
            var fragment = [UInt8](repeating: 0, count: buffSize)
            let count = read(fd, &fragment, buffSize)
            if count < 0 {
                throw MyError.failure
            }
            if count < buffSize {
                buff += fragment[0..<count]
                return Data(bytes: buff)
            }
            buff += fragment
        }
    }
}


func writeFileData(filename: String, data: [UInt8]) throws {
#if os(Linux)
    _ = try NSData(bytes: data, length: data.count).write(to: NSURL(fileURLWithPath: filename))
#else
    _ = try Data(bytes: data).write(to: URL(fileURLWithPath: filename))
#endif
}

func readFileData(filename: String) throws -> [UInt8] {
#if os(Linux)
    guard let data = NSData(contentsOfFile: filename) else {
        throw MyError.failure
    }

    // from NSData to [UInt8]
    return Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(data.bytes), count: data.length))
#else
    return try [UInt8](Data(contentsOf:URL(fileURLWithPath: filename)))
#endif
}
