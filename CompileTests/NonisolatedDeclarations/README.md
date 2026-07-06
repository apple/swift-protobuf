# CompileTests/NonisolatedDeclarations

This is a test case that ensures generated code builds correctly when the
target has "Default Actor Isolation" set to `MainActor` (via
`.defaultIsolation(MainActor.self)`). The generator is configured with
`NonisolatedDeclarations=true` so that generated declarations are marked
`nonisolated` and do not pick up the surrounding MainActor isolation.

Without `NonisolatedDeclarations=true`, the generated structs and extensions
would be implicitly `@MainActor`-isolated and the build would fail with errors
like "Conformance of '...' to protocol '...' crosses into main actor-isolated
code and can cause data races."
