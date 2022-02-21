---
title: HTTP/3 and QPACK qlog event definitions
docname: draft-ietf-quic-qlog-h3-events-latest
category: std

ipr: trust200902
area: Transport
workgroup: QUIC
keyword: Internet-Draft

stand_alone: yes
pi: [toc, docindent, sortrefs, symrefs, strict, compact, comments, inline]

author:
  -
    ins: R. Marx
    name: Robin Marx
    org: KU Leuven
    email: robin.marx@kuleuven.be
  -
    ins: L. Niccolini
    name: Luca Niccolini
    org: Facebook
    email: lniccolini@fb.com
    role: editor
  -
    ins: M. Seemann
    name: Marten Seemann
    org: Protocol Labs
    email: marten@protocol.ai
    role: editor

normative:

  QUIC-HTTP:
    title: "Hypertext Transfer Protocol Version 3 (HTTP/3)"
    date: {DATE}
    seriesinfo:
      Internet-Draft: draft-ietf-quic-http-latest
    author:
      -
          ins: M. Bishop
          name: Mike Bishop
          org: Akamai Technologies
          role: editor

  QUIC-QPACK:
    title: "QPACK: Header Compression for HTTP over QUIC"
    date: {DATE}
    seriesinfo:
      Internet-Draft: draft-ietf-quic-qpack-latest
    author:
      -
          ins: C. Krasic
          name: Charles 'Buck' Krasic
          org: Google, Inc
      -
          ins: M. Bishop
          name: Mike Bishop
          org: Akamai Technologies
      -
          ins: A. Frindell
          name: Alan Frindell
          org: Facebook
          role: editor

  QLOG-MAIN:
    title: "Main logging schema for qlog"
    date: {DATE}
    seriesinfo:
      Internet-Draft: draft-ietf-quic-qlog-main-schema-latest
    author:
      -
        ins: R. Marx
        name: Robin Marx
        org: KU Leuven
        role: editor
      -
        ins: L. Niccolini
        name: Luca Niccolini
        org: Facebook
        role: editor
      -
        ins: M. Seemann
        name: Marten Seemann
        org: Protocol Labs
        role: editor

  QLOG-QUIC:
    title: "QUIC event definitions for qlog"
    date: {DATE}
    seriesinfo:
      Internet-Draft: draft-ietf-quic-qlog-quic-events-latest
    author:
      -
        ins: R. Marx
        name: Robin Marx
        org: KU Leuven
        role: editor
      -
        ins: L. Niccolini
        name: Luca Niccolini
        org: Facebook
        role: editor
      -
        ins: M. Seemann
        name: Marten Seemann
        org: Protocol Labs
        role: editor

informative:

--- abstract

This document describes concrete qlog event definitions and their metadata for
HTTP/3 and QPACK-related events. These events can then be embedded in the higher
level schema defined in [QLOG-MAIN].

--- middle

# Introduction

This document describes the values of the qlog name ("category" + "event") and
"data" fields and their semantics for the HTTP/3 and QPACK protocols. This
document is based on draft-34 of the HTTP/3 I-D [QUIC-HTTP] and draft-21 of the
QPACK I-D [QUIC-QPACK]. QUIC events are defined in a separate document
[QLOG-QUIC].

Feedback and discussion are welcome at
[https://github.com/quicwg/qlog](https://github.com/quicwg/qlog).
Readers are advised to refer to the "editor's draft" at that URL for an up-to-date
version of this document.

Concrete examples of integrations of this schema in
various programming languages can be found at
[https://github.com/quiclog/qlog/](https://github.com/quiclog/qlog/).

## Notational Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in {{?RFC2119}}.

The examples and data definitions in ths document are expressed in a custom data
definition language, inspired by JSON and TypeScript, and described in
[QLOG-MAIN].

# Overview

This document describes the values of the qlog "name" ("category" + "event") and
"data" fields and their semantics for the HTTP/3 and QPACK protocols.

This document assumes the usage of the encompassing main qlog schema defined in
[QLOG-MAIN]. Each subsection below defines a separate category (for example http,
qpack) and each subsubsection is an event type (for example `frame_created`).

For each event type, its importance and data definition is laid out, often
accompanied by possible values for the optional "trigger" field. For the
definition and semantics of "importance" and "trigger", see the main schema
document.

Most of the complex datastructures, enums and re-usable definitions are grouped
together on the bottom of this document for clarity.

## Usage with QUIC

The events described in this document can be used with or without logging the
related QUIC events defined in [QLOG-QUIC]. If used with QUIC events, the QUIC
document takes precedence in terms of recommended filenames and trace separation
setups.

If used without QUIC events, it is recommended that the implementation assign a
globally unique identifier to each HTTP/3 connection. This ID can then be used as
the value of the qlog "group_id" field, as well as the qlog filename or file
identifier, potentially suffixed by the vantagepoint type (For example,
abcd1234_server.qlog would contain the server-side trace of the connection with
GUID abcd1234).

## Links to the main schema

This document re-uses all the fields defined in the main qlog schema (e.g., name,
category, type, data, group_id, protocol_type, the time-related fields,
importance, RawInfo, etc.).

One entry in the "protocol_type" qlog array field MUST be "HTTP3" if events from
this document are included in a qlog trace.

### Raw packet and frame information

This document re-uses the definition of the RawInfo data class from [QLOG-MAIN].

Note:

: As HTTP/3 does not use trailers in frames, each HTTP/3 frame header_length can
be calculated as header_length = RawInfo:length - RawInfo:payload_length

Note:

: In some cases, the length fields are also explicitly reflected inside of frame
headers. For example, all HTTP/3 frames include their explicit payload lengths in
the frame header. In these cases, those fields are intentionally preserved in the
event definitions. Even though this can lead to duplicate data when the full
RawInfo is logged, it allows a more direct mapping of the HTTP/3 specifications to
qlog, making it easier for users to interpret. In this case, both fields MUST have
the same value.


# HTTP/3 and QPACK event definitions

Each subheading in this section is a qlog event category, while each
sub-subheading is a qlog event type.

For example, for the following two items, we have the category "http" and event
type "parameters_set", resulting in a concatenated qlog "name" field value of
"http:parameters_set".

## http

Note: like all category values, the "http" category is written in lowercase.

### parameters_set
Importance: Base

This event contains HTTP/3 and QPACK-level settings, mostly those received from
the HTTP/3 SETTINGS frame. All these parameters are typically set once and never
change. However, they are typically set at different times during the connection,
so there can be several instances of this event with different fields set.

Note that some settings have two variations (one set locally, one requested by the
remote peer). This is reflected in the "owner" field. As such, this field MUST be
correct for all settings included a single event instance. If you need to log
settings from two sides, you MUST emit two separate event instances.

Data:

~~~ cddl-definition
HTTPP3ParametersSet = {
    ? owner: OwnerType
    ; MAX_HEADER_LIST_SIZE
    ? max_header_list_size: uint64
    ; QPACK_MAX_TABLE_CAPACITY
    ? max_table_capacity: uint64
    ; QPACK_BLOCKED_STREAMS
    ? blocked_streams_count: uint64
    ; additional settings for grease and extensions
    * text => uint64
    ; indicates whether this implementation waits for a SETTINGS
    ; frame before processing requests
    ? waits_for_settings: bool
}
~~~

Note: enabling server push is not explicitly done in HTTP/3 by use of a setting or
parameter. Instead, it is communicated by use of the MAX_PUSH_ID frame, which
should be logged using the frame_created and frame_parsed events below.

Additionally, this event can contain any number of unspecified fields. This is to
reflect setting of for example unknown (greased) settings or parameters of
(proprietary) extensions.

### parameters_restored
Importance: Base

When using QUIC 0-RTT, HTTP/3 clients are expected to remember and reuse the
server's SETTINGs from the previous connection. This event is used to indicate
which HTTP/3 settings were restored and to which values when utilizing 0-RTT.

Data:

~~~ cddl-definition
; TODO: this can be moved into its own definition and re-used both here and in ParametersSet
HTTP3ParametersRestore = {
    ? max_header_list_size: uint64
    ; QPACK_MAX_TABLE_CAPACITY
    ? max_table_capacity: uint64
    ; QPACK_BLOCKED_STREAMS
    ? blocked_streams_count: uint64
    ; additional settings for grease and extensions
    * text => uint64
}
~~~

Note that, like for parameters_set above, this event can contain any number of
unspecified fields to allow for additional and custom settings.

### stream_type_set
Importance: Base

Emitted when a stream's type becomes known. This is typically when a stream is
opened and the stream's type indicator is sent or received.

Note: most of this information can also be inferred by looking at a stream's id,
since id's are strictly partitioned at the QUIC level. Even so, this event has a
"Base" importance because it helps a lot in debugging to have this information
clearly spelled out.

Data:

~~~ cddl-definition
HTTP3StreamType = "data" /
             "control" /
             "push" /
             "reserved" /
             "qpack_encode" /
             "qpack_decode"

HTTP3StreamTypeSet = {
    ? owner: OwnerType
    stream_id: uint64
    ? old: StreamType
    new: StreamType
    ; only when new == "push"
    ? associated_push_id
}
~~~

### frame_created
Importance: Core

HTTP equivalent to the packet_sent event. This event is emitted when the HTTP/3
framing actually happens. Note: this is not necessarily the same as when the
HTTP/3 data is passed on to the QUIC layer. For that, see the "data_moved" event
in [QLOG-QUIC].

Data:

~~~ cddl-definition
HTTP3FrameCreated = {
    stream_id: uint64
    ? length: uint64
    frame: HTTP3Frame
    ? raw: RawInfo
}
~~~

Note: in HTTP/3, DATA frames can have arbitrarily large lengths to reduce frame
header overhead. As such, DATA frames can span many QUIC packets and can be
created in a streaming fashion. In this case, the frame_created event is emitted
once for the frame header, and further streamed data is indicated using the
data_moved event.

### frame_parsed
Importance: Core

HTTP equivalent to the packet_received event. This event is emitted when we
actually parse the HTTP/3 frame. Note: this is not necessarily the same as when
the HTTP/3 data is actually received on the QUIC layer. For that, see the
"data_moved" event in [QLOG-QUIC].


Data:

~~~ cddl-definition
; TODO(lnicco): this is the same as FrameCreated. 
; should we have a generic Frame type instead?
HTTP3FrameParsed = {
    stream_id: uint64
    ? length: uint64
    frame: HTTP3Frame
    ? raw: RawInfo
}
~~~

Note: in HTTP/3, DATA frames can have arbitrarily large lengths to reduce frame
header overhead. As such, DATA frames can span many QUIC packets and can be
processed in a streaming fashion. In this case, the frame_parsed event is emitted
once for the frame header, and further streamed data is indicated using the
data_moved event.

### push_resolved
Importance: Extra

This event is emitted when a pushed resource is successfully claimed (used) or,
conversely, abandoned (rejected) by the application on top of HTTP/3 (e.g., the
web browser). This event is added to help debug problems with unexpected PUSH
behaviour, which is commonplace with HTTP/2.

~~~ cddl-definition
HTTP3PushResolved = {
    ? push_id: uint64
    ; in case this is logged from a place that does not have access
    ; to the push_id
    ? stream_id: uint64
    decision: "claimed" / "abandoned"
}
~~~

## qpack

Note: like all category values, the "qpack" category is written in lowercase.

The QPACK events mainly serve as an aid to debug low-level QPACK issues. The
higher-level, plaintext header values SHOULD (also) be logged in the
http.frame_created and http.frame_parsed event data (instead).

Note: qpack does not have its own parameters_set event. This was merged with
http.parameters_set for brevity, since qpack is a required extension for HTTP/3
anyway. Other HTTP/3 extensions MAY also log their SETTINGS fields in
http.parameters_set or MAY define their own events.

### state_updated
Importance: Base

This event is emitted when one or more of the internal QPACK variables changes
value. Note that some variables have two variations (one set locally, one
requested by the remote peer). This is reflected in the "owner" field. As such,
this field MUST be correct for all variables included a single event instance. If
you need to log settings from two sides, you MUST emit two separate event
instances.

Data:

~~~ cddl-definition
QPACKStateUpdate = {
    owner: OwnerType
    ? dynamic_table_capacity: uint64
    ; effective current size, sum of all the entries
    ? dynamic_table_size: uint64
    ? known_received_count: uint64
    ? current_insert_count: uint64
}
~~~

### stream_state_updated
Importance: Core

This event is emitted when a stream becomes blocked or unblocked by header
decoding requests or QPACK instructions.

Note: This event is of "Core" importance, as it might have a large impact on
HTTP/3's observed performance.

Data:


~~~ cddl-definition
QPACKStreamStateUpdate = {
    stream_id: uint64
    ; streams are assumed to start "unblocked" until they become
    ; "blocked"
    state: QPACKStreamState
}

QPACKStreamState = "blocked" / "unblocked"
~~~

### dynamic_table_updated
Importance: Extra

This event is emitted when one or more entries are inserted or evicted from QPACK's dynamic table.

Data:

~~~ cddl-definition
QPACKDynamicTableUpdate = {
    ; local = the encoder's dynamic table
    ; remote = the decoder's dynamic table
    owner: OwnerType
    update_type: QPACKDynamicTableUpdateType
    entries: [+ QPACKDynamicTableEntry]
}

QPACKDynamicTableUpdateType = "inserted" / "evicted"

QPACKDynamicTableEntry = {
    index: uint64
    ? name: text / hexstring
    ? value: text / hexstring
}
~~~

### headers_encoded
Importance: Base

This event is emitted when an uncompressed header block is encoded successfully.

Note: this event has overlap with http.frame_created for the HeadersFrame type.
When outputting both events, implementers MAY omit the "headers" field in this
event.

Data:

~~~ cddl-definition
QPACKHeadersEncoded = {
    ? stream_id: uint64
    ? headers: [+ HTTPHeaders]
    block_prefix: QPACKHeaderBlockPrefix
    header_block: [+ QPACKHeaderBlockRepresentation]
    ? length: uint
    ? raw: hexstring
}
~~~

### headers_decoded
Importance: Base

This event is emitted when a compressed header block is decoded successfully.

Note: this event has overlap with http.frame_parsed for the HeadersFrame type.
When outputting both events, implementers MAY omit the "headers" field in this
event.

Data:

~~~ cddl-definition
QPACKHeadersDecoded = {
    ? stream_id: uint64
    ? headers: [+ HTTPHeaders]
    block_prefix: QPACKHeaderBlockPrefix
    header_block: [+ QPACKHeaderBlockRepresentation]
    ? length: uint
    ? raw: hexstring
}
~~~

### instruction_created
Importance: Base

This event is emitted when a QPACK instruction (both decoder and encoder) is
created and added to the encoder/decoder stream.

Data:

~~~ cddl-definition
QPACKInstructionCreated = {
    ; see definition in appendix
    instruction: QPACKInstruction
    ? length: uint32
    ? raw: hexstring
}
~~~

Note: encoder/decoder semantics and stream_id's are implicit in either the
instruction types or can be logged via other events (e.g., http.stream_type_set)

### instruction_parsed
Importance: Base

This event is emitted when a QPACK instruction (both decoder and encoder) is read
from the encoder/decoder stream.

Data:

~~~ cddl-definition
QPACKInstructionParsed = {
    ; see definition in appendix
    instruction: QPACKInstruction
    ? length: uint32
    ? raw: hexstring
}
~~~

Note: encoder/decoder semantics and stream_id's are implicit in either the
instruction types or can be logged via other events (e.g., http.stream_type_set)

# Security Considerations

TBD

# IANA Considerations

TBD

--- back

# HTTP/3 data field definitions

## HTTP/3 Frames

~~~ cddl-definition
HTTP3Frame = (
    HTTP3DataFrame //
    HTTP3HeadersFrame //
    HTTP3CancelPushFrame //
    HTTP3SettingsFrame //
    HTTP3PushPromiseFrame //
    HTTP3GoawayFrame //
    HTTP3MaxPushIDFrame //
    HTTP3DuplicatePushFrame //
    HTTP3ReservedFrame //
    HTTP3UnknownFrame
)
~~~

### DataFrame
~~~ cddl-definition
HTTP3DataFrame = {
    frame_type: text .default "data"
    ? raw: hexstring
}
~~~

### HeadersFrame

This represents an *uncompressed*, plaintext HTTP Headers frame (e.g., no QPACK
compression is applied).

For example:

~~~
headers: [
  {
    "name": ":path",
    "value": "/"
  },
  {
    "name": ":method",
    "value": "GET"
  },
  {
    "name": ":authority",
    "value": "127.0.0.1:4433"
  },
  {
    "name": ":scheme",
    "value": "https"
  }
]
~~~

~~~ cddl-definition
HTTP3HeadersFrame = {
    frame_type: text .default "headers"
    ; TODO(lnicco): should this be HTTPMessage instead?
    headers: [* HTTPHeader]
}

HTTPHeader = {
    name: text
    value: text
}
~~~

### CancelPushFrame

~~~ cddl-definition
HTTP3CancelPushFrame = {
    frame_type: text .default "cancel_push"
    push_id: uint64
}
~~~

### SettingsFrame

~~~ cddl-definition
HTTP3SettingsFrame = {
    frame_type: text .default "settings"
    settings: [* HTTP3Settings]
}

HTTP3Settings = {
    name: text
    ; TODO(lnicco): this seems wrong setting values are uint64
    value: text
}
~~~

### PushPromiseFrame

~~~ cddl-definition
HTTP3PushPromiseFrame = {
    frame_type: text .default "push_promise"
    push_id: uint64
    ; TODO(lnicco): same as above. This should be HTTPMessage
    headers: [* HTTPHeaders]
}
~~~

### GoAwayFrame

~~~ cddl-definition
HTTP3GoawayFrame = {
    frame_type: text .default "goaway"
    ; Either stream_id or push_id.
    ; This is implicit from the sender of the frame
    id: uint64
}
~~~

### MaxPushIDFrame

~~~ cddl-definition
HTTP3MaxPushIdFrame = {
    frame_type: text .default "max_push_id"
    push_id: uint64
}
~~~

### ReservedFrame

~~~ cddl-definition
HTTP3ReservedFrame = {
    frame_type: text .default "reserved"
    ; TODO(lnicco): I think we should add this
    length: uint64
}
~~~

### UnknownFrame

HTTP/3 re-uses QUIC's UnknownFrame definition, since their values and usage
overlaps. See [QLOG-QUIC].


## ApplicationError

~~~ cddl-definition
HTTP3ApplicationError = (
    "http_no_error" /
    "http_general_protocol_error" /
    "http_internal_error" /
    "http_stream_creation_error" /
    "http_closed_critical_stream" /
    "http_frame_unexpected" /
    "http_frame_error" /
    "http_excessive_load" /
    "http_id_error" /
    "http_settings_error" /
    "http_missing_settings" /
    "http_request_rejected" /
    "http_request_cancelled" /
    "http_request_incomplete" /
    "http_early_response" /
    "http_connect_error" /
    "http_version_fallback"
)
~~~

# QPACK DATA type definitions

## QPACK Instructions

Note: the instructions do not have explicit encoder/decoder types, since there is
no overlap between the insturctions of both types in neither name nor function.

~~~ cddl-definition
QPACKInstruction = (
    SetDynamicTableCapacityInstruction /
    InsertWithNameReferenceInstruction /
    InsertWithoutNameReferenceInstruction /
    DuplicateInstruction /
    SectionAcknowledgementInstruction /
    StreamCancellationInstruction /
    InsertCountIncrementInstruction
)
~~~

### SetDynamicTableCapacityInstruction

~~~ cddl-definition
SetDynamicTableCapacityInstruction = {
    instruction_type: text .default "set_dynamic_table_capacity"
    capacity: uint
}
~~~

### InsertWithNameReferenceInstruction

~~~ cddl-definition
InsertWithNameReferenceInstruction = {
    instruction_type: text .default "insert_with_name_reference"
    table_type: QPACKTableType
    name_index: uint
    huffman_encoded_value: bool
    ? value_length: uint
    ? value: text
}
~~~

### InsertWithoutNameReferenceInstruction

~~~ cddl-definition
InsertWithoutNameReferenceInstruction = {
    instruction_type: text .default "insert_without_name_reference"
    huffman_encoded_name: bool
    ? name_length: uint
    ? name: text
    huffman_encoded_value: bool
    ? value_length: uint
    ? value: text
}
~~~

### DuplicateInstruction

~~~ cddl-definition
DuplicateInstruction = {
    instruction_type: text .default "duplicate"
    index: uint
}
~~~

### SectionAcknowledgementInstruction

~~~ cddl-definition
SectionAcknowledgementInstruction = {
    instruction_type: text .default "section_acknowledgement"
    stream_id: uint64
}
~~~

### StreamCancellationInstruction

~~~ cddl-definition
StreamCancellationInstruction = {
    instruction_type: text .default "stream_cancellation"
    stream_id: uint64
}
~~~

### InsertCountIncrementInstruction

~~~ cddl-definition
InsertCountIncrementInstruction = {
    instruction_type: text .default "insert_count_increment"
    increment: uint
}
~~~

## QPACK Header compression

~~~ cddl-definition
QPACKHeaderBlockRepresentation = (
    IndexedHeaderField /
    LiteralHeaderFieldWithName /
    LiteralHeaderFieldWithoutName
)
~~~

### IndexedHeaderField

Note: also used for "indexed header field with post-base index"

~~~ cddl-definition
IndexedHeaderField = {
    header_field_type: text .default "indexed_header"
    ; MUST be "dynamic" if is_post_base is true
    table_type: QPACKTableType
    index: uint
    ; to represent the "indexed header field with post-base index"
    ; header field type
    is_post_base: bool .default false
}
~~~

### LiteralHeaderFieldWithName

Note: also used for "Literal header field with post-base name reference"

~~~ cddl-definition
LiteralHeaderFieldWithName = {
    header_field_type: text .default "literal_with_name";
    ; the 3rd "N" bit
    preserve_literal: bool
    ; MUST be "dynamic" if is_post_base is true
    table_type: QPACKTableType
    name_index: uint
    huffman_encoded_value: bool
    ? value_length: uint
    ? value: text
    ; to represent the "indexed header field with post-base index"
    ; header field type
    is_post_base: bool .default false
}
~~~

### LiteralHeaderFieldWithoutName

~~~ cddl-definition
LiteralHeaderFieldWithoutName = {
    header_field_type: text .default "literal_without_name";
    ; the 3rd "N" bit
    preserve_literal: bool
    huffman_encoded_name: bool
    ? name_length: uint
    ? name: text
    huffman_encoded_value: bool
    ? value_length: uint
    ? value: text
}
~~~

### QPACKHeaderBlockPrefix

~~~ cddl-definition
QPACKHeaderBlockPrefix = {
    required_insert_count: uint
    sign_bit: bool
    delta_base: uint
}
~~~

### Extra CDDL definitions
~~~ cddl-definition
; TODO(lnicco): Type Definitions. move somewhere else
uint64 = uint .size 8
OwnerType = "local" / "remote"
QPACKTableType = "static" / "dynamic"
~~~


# Change Log

## Since draft-marx-qlog-event-definitions-quic-h3-02:

* These changes were done in preparation of the adoption of the drafts by the QUIC
  working group (#137)
* Split QUIC and HTTP/3 events into two separate documents
* Moved RawInfo, Importance, Generic events and Simulation events to the main
  schema document.

## Since draft-marx-qlog-event-definitions-quic-h3-01:

Major changes:

* Moved data_moved from http to transport. Also made the "from" and "to" fields
  flexible strings instead of an enum (#111,#65)
* Moved packet_type fields to PacketHeader. Moved packet_size field out of
  PacketHeader to RawInfo:length (#40)
* Made events that need to log packet_type and packet_number use a header field
  instead of logging these fields individually
* Added support for logging retry, stateless reset and initial tokens (#94,#86,#117)
* Moved separate general event categories into a single category "generic" (#47)
* Added "transport:connection_closed" event (#43,#85,#78,#49)
* Added version_information and alpn_information events (#85,#75,#28)
* Added parameters_restored events to help clarify 0-RTT behaviour (#88)

Smaller changes:

* Merged loss_timer events into one loss_timer_updated event
* Field data types are now strongly defined (#10,#39,#36,#115)
* Renamed qpack instruction_received and instruction_sent to instruction_created
  and instruction_parsed (#114)
* Updated qpack:dynamic_table_updated.update_type. It now has the value "inserted"
  instead of "added" (#113)
* Updated qpack:dynamic_table_updated. It now has an "owner" field to
  differentiate encoder vs decoder state (#112)
* Removed push_allowed from http:parameters_set (#110)
* Removed explicit trigger field indications from events, since this was moved to
  be a generic property of the "data" field (#80)
* Updated transport:connection_id_updated to be more in line with other similar
  events. Also dropped importance from Core to Base (#45)
* Added length property to PaddingFrame (#34)
* Added packet_number field to transport:frames_processed (#74)
* Added a way to generically log packet header flags (first 8 bits) to
  PacketHeader
* Added additional guidance on which events to log in which situations (#53)
* Added "simulation:scenario" event to help indicate simulation details
* Added "packets_acked" event (#107)
* Added "datagram_ids" to the datagram_X and packet_X events to allow tracking of
  coalesced QUIC packets (#91)
* Extended connection_state_updated with more fine-grained states (#49)


## Since draft-marx-qlog-event-definitions-quic-h3-00:

* Event and category names are now all lowercase
* Added many new events and their definitions
* "type" fields have been made more specific (especially important for PacketType
  fields, which are now called packet_type instead of type)
* Events are given an importance indicator (issue \#22)
* Event names are more consistent and use past tense (issue \#21)
* Triggers have been redefined as properties of the "data" field and updated for most events (issue \#23)

# Design Variations

TBD

# Acknowledgements

Much of the initial work by Robin Marx was done at Hasselt University.

Thanks to Marten Seemann, Jana Iyengar, Brian Trammell, Dmitri Tikhonov, Stephen
Petrides, Jari Arkko, Marcus Ihlar, Victor Vasiliev, Mirja Kühlewind, Jeremy
Lainé, Kazu Yamamoto, Christian Huitema, and Lucas Pardue for their feedback and
suggestions.

