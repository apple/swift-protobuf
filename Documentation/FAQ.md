# Swift Protobuf FAQ

This document is meant to cover some of the common/repeated questions in past
issues/PRs.

## Can you add an option for…

While there are a [_few_ options that control the generated
files](https://github.com/apple/swift-protobuf/blob/main/Documentation/PLUGIN.md#how-to-specify-code-generation-options),
we prefer not to add customization points like this.

The problem with generation options, especially if the change the generated API
surface, is it leads to problems if two pieces of code depend on the same
`.proto` files. If the two pieces of code rely on different option settings, it
may not be possible for them to work correctly together. This can prevent
protobuf-using libraries from being used in the same program.

##  Why aren't there memberwise initializers?

A `.proto` file does not consider the order the fields are listed in as
important, they can be reordered, new fields can be added in any order, etc.
From a protocol buffers point of view, those aren't breaking changes as protocol
buffers were design (especially the binary format) to support doing these things
safely.

This makes it possible for an updated `.proto` file to be incorporated into one
piece of software while maintaining compatibility with other software that has
not been updated. For example, this makes protocol buffers an excellent choice
when you have mobile apps (that may get updated by users at different times)
speaking to a. common server.

This creates problems for member wise initializers. A large codebase taking
advantage of such initializers would need widespread source changes if a new
`.proto` definition changed the order of fields. In addition, member wise
initializers are impractical with very large messages. Imposing an arbitrary
limit on the size of such initializers would provide another avenue for source
code breakage.

Instead the library has standard support for a static `with` method for Messages
that allows a trailing closure to configure the Message:

```
let msg = MyMessage.with {
  $0.myField = "foo"
}
msg.myOtherField = 5  // error: msg is immutable
```

## Helpers for converting enum values to/from strings?

While the library currently has this data, it is internal to the library. There
are issues tracking exposing this in the future (#326, #731), but it is
currently being deferred until a decision is made on how to model _Descriptors_
in the library. In other languages, the _Descriptor_ objects expose the metadata
about Messages and Enums; it allows access to the different Message, Field, Enum
`options` (#761) as well as opening up options for working on a `Message`
generically (where the calling code doesn't know the type at compile time). Most
of this support is pending some design but also waiting to see how Swift decides
to expose similar data publicly from the Swift Runtime.


## Why are field names and enum case names mangled?

Protocol Buffers has a [styleguide](https://protobuf.dev/programming-guides/style/),
and it calls for field names to be _underscore_separated_names_ and enum cases
to be _CAPITALS_WITH_UNDERSCORES_, to support all languages, it also says the
enum cases should be prefixed with the type name (avoids naming collisions in C
based languages).

To make these things more _Swifty_, the generator will use the rules and attempt
to transform them into something _CamelCased_ which is more common in Swift. And
for enum cases, it will attempt to strip the prefix since Swift enum cases are
scoped to the Enum.

Note: There are some issues with these transforms (especially around some edge
case), but changing this code in the generator would effectively be a _breaking_
change in that code that was working could fail to compile due to changes in
this algorithm. So any future changes would have to happen with the library
moves to a new major version and is generally accepting breaking changes.

## What's wrong with `swift_prefix`?

While there is a [`swift_prefix`
`option`](https://github.com/apple/swift-protobuf/blob/main/Documentation/API.md#generated-struct-name)
to override the reuse of the proto `package` when generating the Swift types,
its use is discouraged because it has proven problematic in practice. Since it
ignores the `package` directive, it can easily lead to name conflicts and other
confusion as shared proto definitions evolve over time.

For example, say you have a file that defines _User_ and/or _Settings_, that
will work great without the package prefix until you use a second proto file
that defined a different _User_ and/or _Settings_. Protocol buffers solved this
by having the package in the first place, so by overriding that with a custom
Swift prefix makes you that much more likely to have collisions in the future.

If you are considering a prefix just to make the type names shorter/nicer, then
instead consider using a Swift `typealias` within your source to remap the names
locally where they are used, but keeping the richer name for the full build to
thus avoid the conflicts.

<!-- Swift Codable Suppor -->
