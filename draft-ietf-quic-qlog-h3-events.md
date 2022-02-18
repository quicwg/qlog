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

~~~
{
    owner?:"local" | "remote",

    max_header_list_size?:uint64,  // MAX_HEADER_LIST_SIZE
    max_table_capacity?:uint64,    // QPACK_MAX_TABLE_CAPACITY
    blocked_streams_count?:uint64, // QPACK_BLOCKED_STREAMS

    // qlog-defined
    waits_for_settings?:boolean // indicates whether this
                                // implementation waits for a
                                // SETTINGS frame before
                                // processing requests
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

~~~
{
    max_header_list_size?:uint64,
    max_table_capacity?:uint64,
    blocked_streams_count?:uint64
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

~~~~
{
    stream_id:uint64,

    owner?:"local"|"remote"

    old?:StreamType,
    new:StreamType,

    associated_push_id?:uint64 // only when new == "push"
}

enum StreamType {
    data, // bidirectional request-response streams
    control,
    push,
    reserved,
    qpack_encode,
    qpack_decode
}
~~~~

### frame_created
Importance: Core

HTTP equivalent to the packet_sent event. This event is emitted when the HTTP/3
framing actually happens. Note: this is not necessarily the same as when the
HTTP/3 data is passed on to the QUIC layer. For that, see the "data_moved" event
in [QLOG-QUIC].

Data:

~~~
{
    stream_id:uint64,
    length?:uint64, // payload byte length of the frame
    frame:HTTP3Frame, // see definitions in appendix

    raw?:RawInfo
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

~~~
{
    stream_id:uint64,
    length?:uint64, // payload byte length of the frame
    frame:HTTP3Frame, // see definitions in appendix

    raw?:RawInfo
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

~~~
{
    push_id?:uint64,
    stream_id?:uint64, // in case this is logged from a place that
                       // does not have access to the push_id

    decision:"claimed"|"abandoned"
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

~~~
{
    owner:"local" | "remote",

    dynamic_table_capacity?:uint64,
    dynamic_table_size?:uint64, // effective current size, sum of
                                // all the entries

    known_received_count?:uint64,
    current_insert_count?:uint64
}
~~~

### stream_state_updated
Importance: Core

This event is emitted when a stream becomes blocked or unblocked by header
decoding requests or QPACK instructions.

Note: This event is of "Core" importance, as it might have a large impact on
HTTP/3's observed performance.

Data:

~~~
{
    stream_id:uint64,

    state:"blocked"|"unblocked" // streams are assumed to start
                                // "unblocked" until they become
                                // "blocked"
}
~~~

### dynamic_table_updated
Importance: Extra

This event is emitted when one or more entries are inserted or evicted from QPACK's dynamic table.

Data:

~~~
{
    owner:"local" | "remote", // local = the encoder's dynamic
                              // table. remote = the decoder's
                              // dynamic table

    update_type:"inserted"|"evicted",

    entries:Array<DynamicTableEntry>
}

class DynamicTableEntry {
    index:uint64;
    name?:string | bytes;
    value?:string | bytes;
}
~~~

### headers_encoded
Importance: Base

This event is emitted when an uncompressed header block is encoded successfully.

Note: this event has overlap with http.frame_created for the HeadersFrame type.
When outputting both events, implementers MAY omit the "headers" field in this
event.

Data:

~~~~
{
    stream_id?:uint64,

    headers?:Array<HTTPHeader>,

    block_prefix:QPackHeaderBlockPrefix,
    header_block:Array<QPackHeaderBlockRepresentation>,

    length?:uint32,
    raw?:bytes
}
~~~~

### headers_decoded
Importance: Base

This event is emitted when a compressed header block is decoded successfully.

Note: this event has overlap with http.frame_parsed for the HeadersFrame type.
When outputting both events, implementers MAY omit the "headers" field in this
event.

Data:

~~~~
{
    stream_id?:uint64,

    headers?:Array<HTTPHeader>,

    block_prefix:QPackHeaderBlockPrefix,
    header_block:Array<QPackHeaderBlockRepresentation>,

    length?:uint32,
    raw?:bytes
}
~~~~

### instruction_created
Importance: Base

This event is emitted when a QPACK instruction (both decoder and encoder) is
created and added to the encoder/decoder stream.

Data:

~~~
{
    instruction:QPackInstruction // see definitions in appendix

    length?:uint32,
    raw?:bytes
}
~~~

Note: encoder/decoder semantics and stream_id's are implicit in either the
instruction types or can be logged via other events (e.g., http.stream_type_set)

### instruction_parsed
Importance: Base

This event is emitted when a QPACK instruction (both decoder and encoder) is read
from the encoder/decoder stream.

Data:

~~~
{
    instruction:QPackInstruction // see definitions in appendix

    length?:uint32,
    raw?:bytes
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

~~~
type HTTP3Frame = DataFrame | HeadersFrame | CancelPushFrame |
                  SettingsFrame | PushPromiseFrame |
                  GoAwayFrame | MaxPushIDFrame |
                  DuplicatePushFrame | ReservedFrame |
                  UnknownFrame;
~~~

### DataFrame
~~~
class DataFrame{
    frame_type:string = "data";

    raw?:bytes;
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

~~~
class HeadersFrame{
    frame_type:string = "header";
    headers:Array<HTTPHeader>;
}

class HTTPHeader {
    name:string;
    value:string;
}
~~~

### CancelPushFrame
~~~
class CancelPushFrame{
    frame_type:string = "cancel_push";
    push_id:uint64;
}
~~~

### SettingsFrame
~~~
class SettingsFrame{
    frame_type:string = "settings";
    settings:Array<Setting>;
}

class Setting{
    name:string;
    value:string;
}
~~~

### PushPromiseFrame

~~~
class PushPromiseFrame{
    frame_type:string = "push_promise";
    push_id:uint64;

    headers:Array<HTTPHeader>;
}
~~~

### GoAwayFrame
~~~
class GoAwayFrame{
    frame_type:string = "goaway";
    id:uint64; // either stream_id or push_id. This is implicit
               // from the sender of the frame.
}
~~~

### MaxPushIDFrame
~~~
class MaxPushIDFrame{
    frame_type:string = "max_push_id";
    push_id:uint64;
}
~~~

### DuplicatePushFrame
~~~
class DuplicatePushFrame{
    frame_type:string = "duplicate_push";
    push_id:uint64;
}
~~~

### ReservedFrame
~~~
class ReservedFrame{
    frame_type:string = "reserved";
}
~~~

### UnknownFrame

HTTP/3 re-uses QUIC's UnknownFrame definition, since their values and usage
overlaps. See [QLOG-QUIC].


## ApplicationError
~~~
enum ApplicationError{
    http_no_error,
    http_general_protocol_error,
    http_internal_error,
    http_stream_creation_error,
    http_closed_critical_stream,
    http_frame_unexpected,
    http_frame_error,
    http_excessive_load,
    http_id_error,
    http_settings_error,
    http_missing_settings,
    http_request_rejected,
    http_request_cancelled,
    http_request_incomplete,
    http_early_response,
    http_connect_error,
    http_version_fallback
}
~~~

# QPACK DATA type definitions

## QPACK Instructions

Note: the instructions do not have explicit encoder/decoder types, since there is
no overlap between the insturctions of both types in neither name nor function.

~~~
type QPackInstruction = SetDynamicTableCapacityInstruction |
                        InsertWithNameReferenceInstruction |
                        InsertWithoutNameReferenceInstruction |
                        DuplicateInstruction |
                        HeaderAcknowledgementInstruction |
                        StreamCancellationInstruction |
                        InsertCountIncrementInstruction;
~~~

### SetDynamicTableCapacityInstruction

~~~
class SetDynamicTableCapacityInstruction {
    instruction_type:string = "set_dynamic_table_capacity";

    capacity:uint32;
}
~~~

### InsertWithNameReferenceInstruction

~~~
class InsertWithNameReferenceInstruction {
    instruction_type:string = "insert_with_name_reference";

    table_type:"static"|"dynamic";

    name_index:uint32;

    huffman_encoded_value:boolean;

    value_length?:uint32;
    value?:string;
}
~~~

### InsertWithoutNameReferenceInstruction

~~~
class InsertWithoutNameReferenceInstruction {
    instruction_type:string = "insert_without_name_reference";

    huffman_encoded_name:boolean;

    name_length?:uint32;
    name?:string;

    huffman_encoded_value:boolean;

    value_length?:uint32;
    value?:string;
}
~~~

### DuplicateInstruction

~~~
class DuplicateInstruction {
    instruction_type:string = "duplicate";

    index:uint32;
}
~~~

### HeaderAcknowledgementInstruction

~~~
class HeaderAcknowledgementInstruction {
    instruction_type:string = "header_acknowledgement";

    stream_id:uint64;
}
~~~

### StreamCancellationInstruction

~~~
class StreamCancellationInstruction {
    instruction_type:string = "stream_cancellation";

    stream_id:uint64;
}
~~~

### InsertCountIncrementInstruction

~~~
class InsertCountIncrementInstruction {
    instruction_type:string = "insert_count_increment";

    increment:uint32;
}
~~~

## QPACK Header compression

~~~
type QPackHeaderBlockRepresentation = IndexedHeaderField |
                                      LiteralHeaderFieldWithName |
                                      LiteralHeaderFieldWithoutName;
~~~

### IndexedHeaderField

Note: also used for "indexed header field with post-base index"

~~~
class IndexedHeaderField {
    header_field_type:string = "indexed_header";

    table_type:"static"|"dynamic"; // MUST be "dynamic" if
                                   // is_post_base is true
    index:uint32;

    is_post_base:boolean = false; // to represent the "indexed
                                  // header field with post-base
                                  // index" header field type
}
~~~

### LiteralHeaderFieldWithName

Note: also used for "Literal header field with post-base name reference"

~~~
class LiteralHeaderFieldWithName {
    header_field_type:string = "literal_with_name";

    preserve_literal:boolean; // the 3rd "N" bit
    table_type:"static"|"dynamic"; // MUST be "dynamic" if
                                   // is_post_base is true
    name_index:uint32;

    huffman_encoded_value:boolean;
    value_length?:uint32;
    value?:string;

    is_post_base:boolean = false; // to represent the "Literal
                                  // header field with post-base
                                  // name reference" header field
                                  // type
}
~~~

### LiteralHeaderFieldWithoutName

~~~
class LiteralHeaderFieldWithoutName {
    header_field_type:string = "literal_without_name";

    preserve_literal:boolean; // the 3rd "N" bit

    huffman_encoded_name:boolean;
    name_length?:uint32;
    name?:string;

    huffman_encoded_value:boolean;
    value_length?:uint32;
    value?:string;
}
~~~

### QPackHeaderBlockPrefix

~~~
class QPackHeaderBlockPrefix {
    required_insert_count:uint32;
    sign_bit:boolean;
    delta_base:uint32;
}
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

