# CompileTests/StrictMemorySafety

This test case ensures storage-backed generated messages compile with strict
memory safety and warnings as errors on Swift 6.2 and later. Swift 6.1 uses its
version-specific manifest without the newer compiler flag to verify source
compatibility.
