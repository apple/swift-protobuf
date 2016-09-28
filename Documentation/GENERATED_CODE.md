# Swift Protobuf Generated Code Guide

This explanation of the generated code is intended to help people
understand the design of Swift Protobuf.
This is not a contract: The details of the generated code are
expected to change over time as we discover better ways to
implement the expected behaviors.
As a result, this document is probably already out of date; pull requests
that correct this document to better match the actual behavior are
always appreciated.

## Field Storage

The generated message structs follow one of several different patterns regarding how they store their fields.

### Basic Templates

The simplest pattern is for small proto3 messages that have only basic
field types.
For example, consider the following:
```protobuf
syntax = "proto3";
message Foo {
   int32 field1 = 1;
   string field2 = 2;
}
```
For these, we can generate a simple struct with the expected public properties:
```swift
struct Foo {
   public var field1: Int32 = 0
   public var field2: String = ""
   // Other stuff...
}
```

We can use a similarly simple structure for proto2 messages that only have optional fields with basic field types.
Consider the proto2 analog of the previous example:
```protobuf
syntax = "proto2";
message Foo {
   optional int32 field1 = 1;
   optional string field2 = 2;
}
```
This translates into almost the same structure, except that the fields have a slightly different type:
```swift
struct Foo {
   public var field1: Int32? = nil
   public var fiel2: String? = nil
}
```

If there are default values, we want to ensure that users can reset the field by assigning nil.
In particular, we cannot just change the initialization of the fields above, we need an additional layer of structure.
Here's a simple example where the optional fields have default values:
```protobuf
syntax = "proto2";
message Foo {
    optional int32 field1 = 1 [default = 17];
    optional string field2 = 2 [default = "hello"];
}
```
This gets translated into a private optional and a computed accessor that translates nil into the default.
With this structure, you can simply assign nil to the field to reset it to the default:
```swift
struct Foo {
  private var _field1: Int32? = nil
  public var field1: Int32? {
    get {return _field1 ?? 17}
    set {_field1 = newValue}
  }

  private var _field2: String? = nil
  public var field2: String? {
    get {return _field2 ?? "hello"}
    set {_field2 = newValue}
  }
}
```

Repeated and map fields are handled similarly, except that they cannot have defaults, so the generated code always initializes them to `[]` or `[:]` accordingly.

### Message-valued Fields

Protobuf allows recursive structures such as the following:
```protobuf
syntax = "proto3";
message Foo {
   Foo fooField = 1;
}
```

The simple patterns above cannot correctly handle this because Swift does not permit recursive structs.
To correctly model this, we need to store `fooField` in a separate storage class that will be allocated on the heap:
```swift
struct Foo {
  private class _StorageClass {
    var _fooField: Foo? = nil
  }
  private var _storage: _StorageClass?

  public var fooField: Foo {
    get {return _storage?._fooField ?? Foo()}
    set {_uniqueStorage()._fooField = newValue}
  }

  private mutating func _uniqueStorage() -> _StorageClass { ... }
}
```

With this structure, setting a value for `fooField` will cause a new `_StorageClass` to be allocated on the heap and the value will be stored there.
The `_uniqueStorage()` method is a standard template that provides standard Swift copy-on-write behaviors:
```swift
  private mutating func _uniqueStorage() -> _StorageClass {
    if _storage == nil {
      _storage = _StorageClass()
    } else if !isKnownUniquelyReferenced(&_storage) {
      _storage = _storage!.copy()
    }
    return _storage!
  }
```

Note that the `_uniqueStorage()` method assumes the existence of a `copy()` method on the storage class which is not shown here.

In the current implementation, a storage class is generated in the following cases:

 * If there are any fields containing a message or group type
 * If there are more than 16 total fields

More extensive testing could help fine-tune the logic for when we put fields directly into the struct and when we put them into a storage class.
There might be cases where it makes more sense to put some fields directly into the struct and others into the storage class, but the current implementation will put all fields into the storage class if it decides to use a storage class.

## General Message Information

Each generated struct has a collection of computed variables that return basic information about the struct.

Here is the actual first part of the generated code for `message Foo` above:
```swift
public struct Foo: ProtobufGeneratedMessage {
  public var swiftClassName: String {return "Foo"}
  public var protoMessageName: String {return "Foo"}
  public var protoPackageName: String {return ""}
  public var jsonFieldNames: [String: Int] {return [
    "fooField": 1,
  ]}
  public var protoFieldNames: [String: Int] {return [
    "fooField": 1,
  ]}
```

The `swiftClassName` is used by the `CustomMirror` implementation to populate the Swift classname.
The `protoMessageName` and `protoPackageName` provide information from the `.proto` file for use by various serialization mechanisms.
The `jsonFieldNames` and `protoFieldNames` variables map the respective field names into the field numbers from the proto file.
These are used by various serialization engines in the runtime library.

## Serialization support

The serialization support is based on a traversal mechanism (also known as "The Visitor Pattern").
The various serialization systems in the runtime library construct objects that conform to the `ProtobufVisitor` protocol and then invoke the `traverse()` method which will provide the visitor with a look at every non-empty field.

As above, this varies slightly depending on the proto language dialect, so let's start with a proto3 example:
```protobuf
syntax= "proto3";
message Foo {
  int32 field1 = 1;
  sfixed32 field2 = 2;
  repeated string field3 = 3;
  Foo fooField = 4;
  map<int32,bool> mapField = 5;
}
```

This generates a storage class, of course.
When the serializer invokes `traverse()` on the struct, it simply passes the visitor to `traverse()` on the storage class, which looks like this:
```swift
  private class _StorageClass {
    var _field1: Int32 = 0
    var _field2: Int32 = 0
    var _field3: [String] = []
    var _fooField: Foo? = nil
    var _mapField: Dictionary<Int32,Bool> = [:]

    func traverse(visitor: inout ProtobufVisitor) throws {
      if _field1 != 0 {
        try visitor.visitSingularField(fieldType: ProtobufInt32.self, value: _field1, protoFieldNumber: 1, protoFieldName: "field1", jsonFieldName: "field1", swiftFieldName: "field1")
      }
      if _field2 != 0 {
        try visitor.visitSingularField(fieldType: ProtobufSFixed32.self, value: _field2, protoFieldNumber: 2, protoFieldName: "field2", jsonFieldName: "field2", swiftFieldName: "field2")
      }
      if !_field3.isEmpty {
        try visitor.visitRepeatedField(fieldType: ProtobufString.self, value: _field3, protoFieldNumber: 3, protoFieldName: "field3", jsonFieldName: "field3", swiftFieldName: "field3")
      }
      if let v = _fooField {
        try visitor.visitSingularMessageField(value: v, protoFieldNumber: 4, protoFieldName: "fooField", jsonFieldName: "fooField", swiftFieldName: "fooField")
      }
      if !_mapField.isEmpty {
        try visitor.visitMapField(fieldType: ProtobufMap<ProtobufInt32,ProtobufBool>.self, value: _mapField, protoFieldNumber: 5, protoFieldName: "mapField", jsonFieldName: "mapField", swiftFieldName: "mapField")
      }
    }
  }
```

Since this is proto3, we only need to visit fields whose value is not the default.
The `ProtobufVisitor` protocol specifies a number of `visitXyzField` methods that accept different types of fields.
In addition to the value, each of these methods is given all of the various identifiers for the field:

  * The proto field number is used by the protobuf binary serializer
  * The JSON name is used by the JSON serializer
  * The swift field name is used by the debugDescription implementation (which uses the same traversal mechanism as the serializers)
  * The proto field name is currently unused

Of course, it would be entirely possible to implement other serializers on top of this same machinery as long as they can make use of one of these field identifiers.

For the message visitors, it suffices to provide just the value, since the visitor implementation can obtain any necessary type information through generic arguments.

For other types, this is insufficient:  `field1` and `field2` here both have a Swift type of `Int32`, but that is not enough to determine the correct serialization.
So some of the visitor methods take a separate argument of a type object that contains detailed serialization information.
You can look at the runtime library to see more details about the `ProtobufVisitor` protocol and the various implementations.

## Deserialization support

Deserialization is a rather complex process overall, though the generated code is fairly simple.

The core of the deserialization machinery rests on the generated `decodeField` method.
Here is the `decodeField` method for the example just above:
```swift
  private class _StorageClass {
    var _field1: Int32 = 0
    var _field2: Int32 = 0
    var _field3: [String] = []
    var _fooField: Foo? = nil
    var _mapField: Dictionary<Int32,Bool> = [:]

    func decodeField(setter: inout ProtobufFieldDecoder, protoFieldNumber: Int) throws -> Bool {
      let handled: Bool
      switch protoFieldNumber {
      case 1: handled = try setter.decodeSingularField(fieldType: ProtobufInt32.self, value: &_field1)
      case 2: handled = try setter.decodeSingularField(fieldType: ProtobufSFixed32.self, value: &_field2)
      case 3: handled = try setter.decodeRepeatedField(fieldType: ProtobufString.self, value: &_field3)
      case 4: handled = try setter.decodeSingularMessageField(fieldType: Foo.self, value: &_fooField)
      case 5: handled = try setter.decodeMapField(fieldType: ProtobufMap<ProtobufInt32,ProtobufBool>.self, value: &_mapField)
      default:
        handled = false
      }
      return handled
    }
```

Similar to the traversal system, the `decodeField` method is given an object that conforms to the `ProtobufFieldDecoder` protocol.
This object generally encapsulates whatever information the deserializer can determine without actual schema knowledge.
This method then provides the field decoder with a reference to the appropriate stored property and additional type information (via the same type objects used in the traversal method).
The decoder now has everything it needs to update the field accordingly.

You may notice that the `decodeField()` method here only uses the proto field number:
Recall from earlier that the struct provides properties that can be used to map JSON and proto field names to proto field numbers.
These maps are used by corresponding decoders to translate serialized names into proto field numbers for use here.

## Miscellaneous support methods

TODO: initializers

TODO: isEmpty

TODO: isEqualTo

TODO: _protoc_generated methods

# Enums

TODO

# Groups

TODO

# Extensions

TODO

