// Sources/SwiftProtobuf/Lock.swift - Cross-platform synchronization lock
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Cross-platform synchronization lock adapted from SwiftNIO's `NIOLock`, but
/// using `os_unfair_lock` on Apple platforms as a performance improvement
/// there.
///
// -----------------------------------------------------------------------------

#if canImport(Darwin)
import Darwin
#elseif os(Windows)
import ucrt
import WinSDK
#elseif canImport(Glibc)
@preconcurrency import Glibc
#elseif canImport(Musl)
@preconcurrency import Musl
#elseif canImport(Bionic)
@preconcurrency import Bionic
#elseif canImport(WASILibc)
@preconcurrency import WASILibc
#if canImport(wasi_pthread)
import wasi_pthread
#endif
#else
#error("Unable to identify your C library")
#endif

/// A threading lock based on `os_unfair_lock` on Apple platforms, `SRWLOCK` on
/// Windows, and `pthread_mutex_t` on other POSIX platforms.
///
/// - Note: ``Lock`` has reference semantics.
struct Lock: ~Copyable {
    @usableFromInline
    let _storage: LockStorage<Void>

    /// Create a new lock.
    @inlinable
    init() {
        self._storage = .create(value: ())
    }

    /// Acquire the lock for the duration of the given block.
    ///
    /// - Parameter body: The block to execute while holding the lock.
    /// - Returns: The value returned by the block.
    @inlinable
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return try body()
    }

    /// Acquire the lock.
    @inlinable
    func lock() {
        self._storage.lock()
    }

    /// Release the lock.
    @inlinable
    func unlock() {
        self._storage.unlock()
    }
}

extension Lock: @unchecked Sendable {}

#if canImport(Darwin)
@usableFromInline
typealias LockPrimitive = os_unfair_lock_s
#elseif os(Windows)
@usableFromInline
typealias LockPrimitive = SRWLOCK
#elseif os(FreeBSD) || os(OpenBSD)
@usableFromInline
typealias LockPrimitive = pthread_mutex_t?
#else
@usableFromInline
typealias LockPrimitive = pthread_mutex_t
#endif

@usableFromInline
enum LockOperations: Sendable {
    @inlinable
    static func create(_ mutex: UnsafeMutablePointer<LockPrimitive>) {
        mutex.assertValidAlignment()

        #if canImport(Darwin)
        mutex.initialize(to: os_unfair_lock_s())
        #elseif os(Windows)
        InitializeSRWLock(mutex)
        #elseif os(FreeBSD) || os(OpenBSD)
        var attr = pthread_mutexattr_t(bitPattern: 0)
        pthread_mutexattr_init(&attr)
        let err = pthread_mutex_init(mutex, &attr)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        #elseif (compiler(<6.1) && !os(WASI)) || (compiler(>=6.1) && _runtime(_multithreaded))
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        #if DEBUG
        pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_ERRORCHECK))
        #endif

        let err = pthread_mutex_init(mutex, &attr)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        #endif
    }

    @inlinable
    static func destroy(_ mutex: UnsafeMutablePointer<LockPrimitive>) {
        mutex.assertValidAlignment()

        #if canImport(Darwin)
        // os_unfair_lock does not need to be freed
        #elseif os(Windows)
        // SRWLOCK does not need to be freed
        #elseif (compiler(<6.1) && !os(WASI)) || (compiler(>=6.1) && _runtime(_multithreaded))
        let err = pthread_mutex_destroy(mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        #endif
    }

    @inlinable
    static func lock(_ mutex: UnsafeMutablePointer<LockPrimitive>) {
        mutex.assertValidAlignment()

        #if canImport(Darwin)
        os_unfair_lock_lock(mutex)
        #elseif os(Windows)
        AcquireSRWLockExclusive(mutex)
        #elseif (compiler(<6.1) && !os(WASI)) || (compiler(>=6.1) && _runtime(_multithreaded))
        let err = pthread_mutex_lock(mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        #endif
    }

    @inlinable
    static func unlock(_ mutex: UnsafeMutablePointer<LockPrimitive>) {
        mutex.assertValidAlignment()

        #if canImport(Darwin)
        os_unfair_lock_unlock(mutex)
        #elseif os(Windows)
        ReleaseSRWLockExclusive(mutex)
        #elseif (compiler(<6.1) && !os(WASI)) || (compiler(>=6.1) && _runtime(_multithreaded))
        let err = pthread_mutex_unlock(mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        #endif
    }
}

// Tail allocate both the mutex and a generic value using ManagedBuffer.
// Both the header pointer and the elements pointer are stable for
// the class's entire lifetime.
//
// See https://github.com/apple/swift-nio/blob/main/Sources/NIOConcurrencyHelpers/NIOLock.swift
// for more information about why this stores the lock in the "elements" section
// of the buffer instead of the header.
@usableFromInline
final class LockStorage<Value>: ManagedBuffer<Value, LockPrimitive> {
    @inlinable
    static func create(value: Value) -> Self {
        let buffer = Self.create(minimumCapacity: 1) { _ in
            value
        }
        let storage = unsafeDowncast(buffer, to: Self.self)
        storage.withUnsafeMutablePointers { _, lockPtr in
            LockOperations.create(lockPtr)
        }
        return storage
    }

    @inlinable
    func lock() {
        self.withUnsafeMutablePointerToElements { lockPtr in
            LockOperations.lock(lockPtr)
        }
    }

    @inlinable
    func unlock() {
        self.withUnsafeMutablePointerToElements { lockPtr in
            LockOperations.unlock(lockPtr)
        }
    }

    @inlinable
    deinit {
        self.withUnsafeMutablePointerToElements { lockPtr in
            LockOperations.destroy(lockPtr)
        }
    }
}

// This compiler guard is here because `ManagedBuffer` is already declaring
// Sendable unavailability after 6.1, which `LockStorage` inherits.
#if compiler(<6.2)
@available(*, unavailable)
extension LockStorage: Sendable {}
#endif

extension UnsafeMutablePointer {
    @inlinable
    func assertValidAlignment() {
        assert(UInt(bitPattern: self) % UInt(MemoryLayout<Pointee>.alignment) == 0)
    }
}
