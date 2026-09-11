# ``Google_Protobuf_Timestamp``

## Topics

### Creating a default instance

- ``init()``

### Creating a timestamp

- ``init(seconds:nanos:)``
- ``init(date:)``

### Converting to and from Date

- ``date``

### Converting to and from a Unix time interval

- ``init(roundingTimeIntervalSince1970:rule:)``
- ``timeIntervalSince1970``
- ``init(timeIntervalSince1970:)``

### Converting to and from a reference-date time interval

- ``init(roundingTimeIntervalSinceReferenceDate:rule:)``
- ``timeIntervalSinceReferenceDate``
- ``init(timeIntervalSinceReferenceDate:)``

### Performing arithmetic

- ``+(_:_:)-(Google_Protobuf_Timestamp,_)``
- ``+(_:_:)-(_,Google_Protobuf_Timestamp)``
- ``-(_:_:)->Google_Protobuf_Timestamp``
- ``-(_:_:)-(_,Google_Protobuf_Timestamp)``

### Handling unknown fields

- ``unknownFields``
