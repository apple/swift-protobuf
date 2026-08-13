# ``Google_Protobuf_Duration``

## Topics

### Creating a default instance

- ``init()``

### Creating a duration

- ``init(seconds:nanos:)``
- ``init(floatLiteral:)``
- ``init(rounding:rule:)-(TimeInterval,_)``
- ``init(rounding:rule:)-(Duration,_)``

### Converting to and from TimeInterval

- ``timeInterval``
- ``init(timeInterval:)``

### Performing arithmetic

- ``+(_:_:)->Google_Protobuf_Duration``
- ``-(_:_:)-(Google_Protobuf_Duration,_)``
- ``-(_:)``

### Satisfying literal-protocol requirements

- ``FloatLiteralType``

### Handling unknown fields

- ``unknownFields``
