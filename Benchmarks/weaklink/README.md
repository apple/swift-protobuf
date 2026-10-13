# Weak-linking proto module dependencies

Reproduces the binary-size effect of `@_weakLinked import` on proto-to-proto
dependencies, and pins down what it does and does not buy.

```sh
./run.py                                        # against the containing checkout
SP_GEN_OPTS=ExperimentalHiddenNames=All ./run.py
```

## Setup

`Common` holds 40 generated message types. `App` has one message with one field whose
type is `common.Shared00`. The program references that one type and nothing else in
`Common`. This is the shape a real app has. Any one client touches a small fraction of a
large shared proto module.

SwiftProtobuf is built once as a shared library and linked dynamically by everything. The
runtime is therefore a constant outside every number below. Without that, each image
statically absorbs its own ~1 MB copy of the runtime and hides the generated-code
differences.

## Findings

**`@_weakLinked import` on its own changes nothing.** The `__text` is identical for
static-strong vs static-weak and dynamic-strong vs dynamic-weak. That is not a
disappointment. It is the definition. Weak-linking changes symbol *binding*, not what the
linker keeps. In the static case the symbols are defined in the same link unit, so
weakness is irrelevant. In the dynamic case the dependency defines its own size, not the
way the client imports it.

The static link also keeps all 40 types. `-dead_strip` does not remove the 39 that are
never referenced, because each generated type's protocol conformance records act as
roots.

**What pays off is a drop of the dependency entirely.** With `@_weakLinked import` plus
`-weak-lCommon`, an app that references `Shared00` only through the structure of the
generated schema, and never reaches the field, runs correctly with `libCommon.dylib`
absent:

| | total `__text` |
|---|---|
| dynamic, dependency shipped | 114,688 |
| dynamic, dependency omitted | 16,384 |

That is an 86% reduction. It scales with how much of the shared module the client does
not use. The effect is therefore large in an app with thousands of generated protos
rather than forty.

**The cost is that there is no graceful degradation.** An app built the same way that
*does* reach `payload.f0` takes a `SIGSEGV` when the dependency is absent. The repro
records this as `touching_omitted_type_runs=0`. There is no diagnostic and no fallback.
The technique trades a link-time guarantee for a runtime one. It is only sound where
something else guarantees that those fields are never touched.

## Gotchas

`@_weakLinked` must be on **every** file in the module that imports the dependency.
Swift rejects a module imported `@_weakLinked` in one file and normally in another
(`'Common' inconsistently imported with @_weakLinked`). A generator option that only
annotates generated files is therefore not enough. Hand-written app code that imports a
proto module must be annotated too.

To check whether an omitted dependency is really gone, move the dylib at its install-name
path. A copy left anywhere else is still found through that absolute path. It then quietly
makes a broken configuration look like it works.
