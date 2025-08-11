// Sources/protoc-gen-swift/Version.swift - Protoc plugin version info
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A simple static object that provides information about the plugin.
///
// ----------------------------------------------------------------------------

import SwiftProtobuf

struct Version {
    // The "compatibility version" of the runtime library, which must be incremented
    // every time a breaking change (either behavioral or API-changing) is introduced
    // and the current runtime can no longer support older generated code.
    //
    // This matches the value in the runtime library itself, this is what is recorded
    // into the generated code. This library ensures that  generated code from a given
    // version will work with the current and future versions (that share this
    // `compatibilityVersion` value), but may not work with older versions.
    static let compatibilityVersion = 2

    static let copyright = "Copyright (C) 2014-2017 Apple Inc. and the project authors"
}
