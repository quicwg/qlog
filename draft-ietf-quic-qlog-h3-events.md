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
  - ins: L. Pardue
    name: Lucas Pardue
    org: Cloudflare
    email: lucaspardue.24.7@gmail.com
    role: editor

normative:

  RFC9114:
    display: HTTP/3

  QLOG-MAIN:
    I-D.ietf-quic-qlog-main-schema

  QLOG-QUIC:
    I-D.ietf-quic-qlog-quic-events

informative:

--- abstract

This document describes concrete qlog event definitions and their metadata for
HTTP/3 and QPACK-related events. These events can then be embedded in the higher
level schema defined in {{QLOG-MAIN}}.

--- middle

# Introduction

This document describes the values of the qlog name ("category" + "event") and
"data" fields and their semantics for HTTP/3 {{RFC9114}} and QPACK
{{!QPACK=RFC9204}}.

> Note to RFC editor: Please remove the follow paragraphs in this section before
publication.

Feedback and discussion are welcome at
[https://github.com/quicwg/qlog](https://github.com/quicwg/qlog).
Readers are advised to refer to the "editor's draft" at that URL for an up-to-date
version of this document.

Concrete examples of integrations of this schema in
various programming languages can be found at
[https://github.com/quiclog/qlog/](https://github.com/quiclog/qlog/).

## Notational Conventions

{::boilerplate bcp14-tagged}

The event and data structure definitions in ths document are expressed
in the Concise Data Definition Language {{!CDDL=RFC8610}} and its
extensions described in {{QLOG-MAIN}}.

The following fields from {{QLOG-MAIN}} are imported and used: name, category,
type, data, group_id, protocol_type, importance, RawInfo, and time-related
fields.

# Overview

This document describes how the HTTP/3 and QPACK can be expressed in qlog using
the schema defined in {{QLOG-MAIN}}. HTTP/3 and QPACK events are defined with a
category, a name (the concatenation of "category" and "event"), an "importance",
an optional "trigger", and "data" fields.

Some data fields use complex datastructures. These are represented as enums or
re-usable definitions, which are grouped together on the bottom of this document
for clarity.

When any event from this document is included in a qlog trace, the
"protocol_type" qlog array field MUST contain an entry with the value "HTTP3".

## Usage with QUIC

The events described in this document can be used with or without logging the
related QUIC events defined in {{QLOG-QUIC}}. If used with QUIC events, the QUIC
document takes precedence in terms of recommended filenames and trace separation
setups.

If used without QUIC events, it is recommended that the implementation assign a
globally unique identifier to each HTTP/3 connection. This ID can then be used as
the value of the qlog "group_id" field, as well as the qlog filename or file
identifier, potentially suffixed by the vantagepoint type (For example,
abcd1234_server.qlog would contain the server-side trace of the connection with
GUID abcd1234).

## Raw packet and frame information

This document re-uses the definition of the RawInfo data class from {{QLOG-MAIN}}.

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

This document defines events in two categories: http ({{http-ev}}) and qpack
({{qpack-ev}}).

As described in {{Section 3.4.2 of QLOG-MAIN}}, the qlog "name" field is the
concatenation of category and type.

{{h3-qpack-events}} summarizes the name value of each event type that is defined
in this specification.

| Name value                  |  Definition |
|:----------------------------|:------------|
| http:parameters_set         | {{http-parametersset}} |
| http:parameters_restored    | {{http-parametersrestored}} |
| http:stream_type_set        | {{http-streamtypeset}} |
| http:frame_created          | {{http-framecreated}} |
| http:frame_parsed           | {{http-frameparsed}} |
| http:push_resolved          | {{http-pushresolved}} |
| qpack:state_updated         | {{qpack-stateupdated}} |
| qpack:stream_state_updated  | {{qpack-streamstateupdate}} |
| qpack:dynamic_table_updated | {{qpack-dynamictableupdate}} |
| qpack:headers_encoded       | {{qpack-headersencoded}} |
| qpack:headers_decoded       | {{qpack-headersdecoded}} |
| qpack:instruction_created   | {{qpack-instructioncreated}} |
| qpack:instruction_parsed    | {{qpack-instructionparsed}} |
{: #h3-qpack-events title="HTTP/3 and QPACK Events"}

# HTTP/3 events {#http-ev}

Note: like all category values, the "http" category is written in lowercase.

## parameters_set {#http-parametersset}
Importance: Base

This event contains HTTP/3 and QPACK-level settings, mostly those received from
the HTTP/3 SETTINGS frame. All these parameters are typically set once and never
change. However, they are typically set at different times during the connection,
so there can be several instances of this event with different fields set.

Note that some settings have two variations (one set locally, one requested by the
remote peer). This is reflected in the "owner" field. As such, this field MUST be
correct for all settings included a single event instance. If you need to log
settings from two sides, you MUST emit two separate event instances.

Note: we use the CDDL unwrap operator (~) here to make HTTPParameters
into a re-usable list of fields. The unwrap operator copies the fields
from the referenced type into the target type directly, extending the
target with the unwrapped fields. TODO: explain this better + provide
reference and maybe an example.

Definition:

~~~ cddl
HTTPParametersSet = {
    ? owner: Owner

    ~HTTPParameters

    ; qlog-specific
    ; indicates whether this implementation waits for a SETTINGS
    ; frame before processing requests
    ? waits_for_settings: bool
}

HTTPParameters = {
    ? max_header_list_size: uint64
    ? max_table_capacity: uint64
    ? blocked_streams_count: uint64

    ; additional settings for grease and extensions
    * text => uint64
}
~~~
{: #http-parametersset-def title="HTTPParametersSet definition"}

Note: enabling server push is not explicitly done in HTTP/3 by use of a setting or
parameter. Instead, it is communicated by use of the MAX_PUSH_ID frame, which
should be logged using the frame_created and frame_parsed events below.

Additionally, this event can contain any number of unspecified fields. This is to
reflect setting of for example unknown (greased) settings or parameters of
(proprietary) extensions.

## parameters_restored {#http-parametersrestored}
Importance: Base

When using QUIC 0-RTT, HTTP/3 clients are expected to remember and reuse the
server's SETTINGs from the previous connection. This event is used to indicate
which HTTP/3 settings were restored and to which values when utilizing 0-RTT.

Definition:

~~~ cddl
HTTPParametersRestored = {

    ~HTTPParameters

}
~~~
{: #http-parametersrestored-def title="HTTPParametersRestored definition"}

Note that, like for parameters_set above, this event can contain any number of
unspecified fields to allow for additional and custom settings.

## stream_type_set {#http-streamtypeset}
Importance: Base

Emitted when a stream's type becomes known. This is typically when a stream is
opened and the stream's type indicator is sent or received.

Note: most of this information can also be inferred by looking at a stream's id,
since id's are strictly partitioned at the QUIC level. Even so, this event has a
"Base" importance because it helps a lot in debugging to have this information
clearly spelled out.

Definition:

~~~ cddl
HTTPStreamTypeSet = {
    ? owner: Owner
    stream_id: uint64

    ? old: HTTPStreamType
    new: HTTPStreamType

    ; only when new === "push"
    ? associated_push_id: uint64
}

HTTPStreamType =  "data" /
                  "control" /
                  "push" /
                  "reserved" /
                  "qpack_encode" /
                  "qpack_decode"
~~~
{: #https-streamtypeset-def title="HTTPStreamTypeSet definition"}

## frame_created {#http-framecreated}
Importance: Core

HTTP equivalent to the packet_sent event. This event is emitted when the HTTP/3
framing actually happens. Note: this is not necessarily the same as when the
HTTP/3 data is passed on to the QUIC layer. For that, see the "data_moved" event
in {{QLOG-QUIC}}.

Definition:

~~~ cddl
HTTPFrameCreated = {
    stream_id: uint64
    ? length: uint64
    frame: HTTPFrame
    ? raw: RawInfo
}
~~~
{: #http-framecreated-def title="HTTPFrameCreated definition"}

Note: in HTTP/3, DATA frames can have arbitrarily large lengths to reduce frame
header overhead. As such, DATA frames can span many QUIC packets and can be
created in a streaming fashion. In this case, the frame_created event is emitted
once for the frame header, and further streamed data is indicated using the
data_moved event.

## frame_parsed {#http-frameparsed}
Importance: Core

HTTP equivalent to the packet_received event. This event is emitted when we
actually parse the HTTP/3 frame. Note: this is not necessarily the same as when
the HTTP/3 data is actually received on the QUIC layer. For that, see the
"data_moved" event in {{QLOG-QUIC}}.


Definition:

~~~ cddl
HTTPFrameParsed = {
    stream_id: uint64
    ? length: uint64
    frame: HTTPFrame
    ? raw: RawInfo
}
~~~
{: #http-frameparsed-def title="HTTPFrameParsed definition"}

Note: in HTTP/3, DATA frames can have arbitrarily large lengths to reduce frame
header overhead. As such, DATA frames can span many QUIC packets and can be
processed in a streaming fashion. In this case, the frame_parsed event is emitted
once for the frame header, and further streamed data is indicated using the
data_moved event.

## push_resolved {#http-pushresolved}
Importance: Extra

This event is emitted when a pushed resource is successfully claimed (used) or,
conversely, abandoned (rejected) by the application on top of HTTP/3 (e.g., the
web browser). This event is added to help debug problems with unexpected PUSH
behaviour, which is commonplace with HTTP/2.

Definition:

~~~ cddl
HTTPPushResolved = {
    ? push_id: uint64

    ; in case this is logged from a place that does not have access
    ; to the push_id
    ? stream_id: uint64

    decision: HTTPPushDecision
}

HTTPPushDecision = "claimed" / "abandoned"
~~~
{: #http-pushresolved-def title="HTTPPushResolved definition"}

# qpack {#qpack-ev}

Note: like all category values, the "qpack" category is written in lowercase.

The QPACK events mainly serve as an aid to debug low-level QPACK issues. The
higher-level, plaintext header values SHOULD (also) be logged in the
http.frame_created and http.frame_parsed event data (instead).

Note: qpack does not have its own parameters_set event. This was merged with
http.parameters_set for brevity, since qpack is a required extension for HTTP/3
anyway. Other HTTP/3 extensions MAY also log their SETTINGS fields in
http.parameters_set or MAY define their own events.

## state_updated {#qpack-stateupdated}
Importance: Base

This event is emitted when one or more of the internal QPACK variables changes
value. Note that some variables have two variations (one set locally, one
requested by the remote peer). This is reflected in the "owner" field. As such,
this field MUST be correct for all variables included a single event instance. If
you need to log settings from two sides, you MUST emit two separate event
instances.

Definition:

~~~ cddl
QPACKStateUpdate = {
    owner: Owner
    ? dynamic_table_capacity: uint64

    ; effective current size, sum of all the entries
    ? dynamic_table_size: uint64
    ? known_received_count: uint64
    ? current_insert_count: uint64
}
~~~
{: #qpack-stateupdate-def title="QPACKStateUpdate definition"}

## stream_state_updated {#qpack-streamstateupdate}
Importance: Core

This event is emitted when a stream becomes blocked or unblocked by header
decoding requests or QPACK instructions.

Note: This event is of "Core" importance, as it might have a large impact on
HTTP/3's observed performance.

Definition:

~~~ cddl
QPACKStreamStateUpdate = {
    stream_id: uint64
    ; streams are assumed to start "unblocked"
    ; until they become "blocked"
    state: QPACKStreamState
}

QPACKStreamState = "blocked" / "unblocked"
~~~
{: #qpack-streamstateupdate-def title="QPACKStreamStateUpdate definition"}

## dynamic_table_updated {#qpack-dynamictableupdate}
Importance: Extra

This event is emitted when one or more entries are inserted or evicted from QPACK's dynamic table.

Definition:

~~~ cddl
QPACKDynamicTableUpdate = {
    ; local = the encoder's dynamic table
    ; remote = the decoder's dynamic table
    owner: Owner

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
{: #qpack-dynamictableupdate-def title="QPACKDynamicTableUpdate definition"}

## headers_encoded {#qpack-headersencoded}
Importance: Base

This event is emitted when an uncompressed header block is encoded successfully.

Note: this event has overlap with http.frame_created for the HeadersFrame type.
When outputting both events, implementers MAY omit the "headers" field in this
event.

Definition:

~~~ cddl
QPACKHeadersEncoded = {
    ? stream_id: uint64
    ? headers: [+ HTTPField]

    block_prefix: QPACKHeaderBlockPrefix
    header_block: [+ QPACKHeaderBlockRepresentation]

    ? length: uint
    ? raw: hexstring
}
~~~
{: #qpack-headersencoded-def title="QPACKHeadersEncoded definition"}

## headers_decoded {#qpack-headersdecoded}
Importance: Base

This event is emitted when a compressed header block is decoded successfully.

Note: this event has overlap with http.frame_parsed for the HeadersFrame type.
When outputting both events, implementers MAY omit the "headers" field in this
event.

Definition:

~~~ cddl
QPACKHeadersDecoded = {
    ? stream_id: uint64
    ? headers: [+ HTTPField]

    block_prefix: QPACKHeaderBlockPrefix
    header_block: [+ QPACKHeaderBlockRepresentation]

    ? length: uint32
    ? raw: hexstring
}
~~~
{: #qpack-headersdecoded-def title="QPACKHeadersDecoded definition"}

## instruction_created {#qpack-instructioncreated}
Importance: Base

This event is emitted when a QPACK instruction (both decoder and encoder) is
created and added to the encoder/decoder stream.

Definition:

~~~ cddl
QPACKInstructionCreated = {
    ; see definition in appendix
    instruction: QPACKInstruction
    ? length: uint32
    ? raw: hexstring
}
~~~
{: #qpack-instructioncreated-def title="QPACKInstructionCreated definition"}

Note: encoder/decoder semantics and stream_id's are implicit in either the
instruction types or can be logged via other events (e.g., http.stream_type_set)

## instruction_parsed {#qpack-instructionparsed}
Importance: Base

This event is emitted when a QPACK instruction (both decoder and encoder) is read
from the encoder/decoder stream.

Definition:

~~~ cddl
QPACKInstructionParsed = {
    ; see QPACKInstruction definition in appendix
    instruction: QPACKInstruction

    ? length: uint32
    ? raw: hexstring
}
~~~
{: #qpack-instructionparsed-def title="QPACKInstructionParsed definition"}

Note: encoder/decoder semantics and stream_id's are implicit in either the
instruction types or can be logged via other events (e.g., http.stream_type_set)

# Security Considerations

TBD

# IANA Considerations

TBD

--- back

# HTTP/3 data field definitions

## ProtocolEventBody extension

We extend the `$ProtocolEventBody` extension point defined in
{{QLOG-MAIN}} with the HTTP/3 protocol events defined in this document.

~~~ cddl
HTTPEvents = HTTPParametersSet / HTTPParametersRestored /
             HTTPStreamTypeSet / HTTPFrameCreated /
             HTTPFrameParsed / HTTPPushResolved

$ProtocolEventBody /= HTTPEvents
~~~
{: #httpevents-def title="HTTPEvents definition and ProtocolEventBody
extension"}

## Owner

~~~ cddl
Owner = "local" / "remote"
~~~
{: #owner-def title="Owner definition"}

## HTTP/3 Frames

~~~ cddl
HTTPFrame =  HTTPDataFrame /
             HTTPHeadersFrame /
             HTTPCancelPushFrame /
             HTTPSettingsFrame /
             HTTPPushPromiseFrame /
             HTTPGoawayFrame /
             HTTPMaxPushIDFrame /
             HTTPReservedFrame /
             UnknownFrame
~~~
{: #httpframe-def title="HTTPFrame definition"}

### DataFrame
~~~ cddl
HTTPDataFrame = {
    frame_type: "data"
    ? raw: hexstring
}
~~~
{: #httpdataframe-def title="HTTPDataFrame definition"}

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
{: #http-headersframe-ex title="HTTPHeadersFrame example"}

~~~ cddl
HTTPHeadersFrame = {
    frame_type: "headers"
    headers: [* HTTPField]
}
~~~
{: #http-headersframe-def title="HTTPHeadersFrame definition"}

~~~ cddl
HTTPField = {
    name: text
    value: text
}
~~~
{: #httpfield-def title="HTTPField definition"}

### CancelPushFrame

~~~ cddl
HTTPCancelPushFrame = {
    frame_type: "cancel_push"
    push_id: uint64
}
~~~
{: #http-cancelpushframe-def title="HTTPCancelPushFrame definition"}

### SettingsFrame

~~~ cddl
HTTPSettingsFrame = {
    frame_type: "settings"
    settings: [* HTTPSetting]
}

HTTPSetting = {
    name: text
    value: uint64
}
~~~
{: #httpsettingsframe-def title="HTTPSettingsFrame definition"}

### PushPromiseFrame

~~~ cddl
HTTPPushPromiseFrame = {
    frame_type: "push_promise"
    push_id: uint64
    headers: [* HTTPField]
}
~~~
{: #httppushpromiseframe-def title="HTTPPushPromiseFrame definition"}

### GoAwayFrame

~~~ cddl
HTTPGoawayFrame = {
    frame_type: "goaway"

    ; Either stream_id or push_id.
    ; This is implicit from the sender of the frame
    id: uint64
}
~~~
{: #httpgoawayframe-def title="HTTPGoawayFrame definition"}

### MaxPushIDFrame

~~~ cddl
HTTPMaxPushIDFrame = {
    frame_type: "max_push_id"
    push_id: uint64
}
~~~
{: #httpmaxpushidframe-def title="HTTPMaxPushIDFrame definition"}

### ReservedFrame

~~~ cddl
HTTPReservedFrame = {
    frame_type: "reserved"

    ? length: uint64
}
~~~
{: #httpreservedframe-def title="HTTPReservedFrame definition"}

### UnknownFrame

HTTP/3 qlog re-uses QUIC's UnknownFrame definition, since their values
and usage overlaps. See {{QLOG-QUIC}}.

## ApplicationError

~~~ cddl
HTTPApplicationError =  "http_no_error" /
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
~~~
{: #httpapplicationerror-def title="HTTPApplicationError definition"}

The HTTPApplicationError defines the general $ApplicationError
definition in the qlog QUIC definition, see {{QLOG-QUIC}}.

~~~ cddl
; ensure HTTP errors are properly validate in QUIC events as well
; e.g., QUIC's ConnectionClose Frame
$ApplicationError /= HTTPApplicationError
~~~

# QPACK DATA type definitions

## ProtocolEventBody extension

We extend the `$ProtocolEventBody` extension point defined in
{{QLOG-MAIN}} with the QPACK protocol events defined in this document.

~~~ cddl
QPACKEvents = QPACKStateUpdate / QPACKStreamStateUpdate /
              QPACKDynamicTableUpdate / QPACKHeadersEncoded /
              QPACKHeadersDecoded / QPACKInstructionCreated /
              QPACKInstructionParsed

$ProtocolEventBody /= QPACKEvents
~~~
{: #qpackevents-def title="QPACKEvents definition and ProtocolEventBody
extension"}

## QPACK Instructions

Note: the instructions do not have explicit encoder/decoder types, since there is
no overlap between the instructions of both types in neither name nor function.

~~~ cddl
QPACKInstruction =  SetDynamicTableCapacityInstruction /
                    InsertWithNameReferenceInstruction /
                    InsertWithoutNameReferenceInstruction /
                    DuplicateInstruction /
                    SectionAcknowledgementInstruction /
                    StreamCancellationInstruction /
                    InsertCountIncrementInstruction
~~~
{: #qpackinstruction-def title="QPACKInstruction definition"}

### SetDynamicTableCapacityInstruction

~~~ cddl
SetDynamicTableCapacityInstruction = {
    instruction_type: "set_dynamic_table_capacity"
    capacity: uint32
}
~~~
{: #setdynamictablecapacityinstruction-def
title="SetDynamicTableCapacityInstruction definition"}

### InsertWithNameReferenceInstruction

~~~ cddl
InsertWithNameReferenceInstruction = {
    instruction_type: "insert_with_name_reference"
    table_type: QPACKTableType
    name_index: uint32
    huffman_encoded_value: bool
    ? value_length: uint32
    ? value: text
}
~~~
{: #insertwithnamereferenceinstruction-def
title="InsertWithNameReferenceInstruction definition"}

### InsertWithoutNameReferenceInstruction

~~~ cddl
InsertWithoutNameReferenceInstruction = {
    instruction_type: "insert_without_name_reference"
    huffman_encoded_name: bool
    ? name_length: uint32
    ? name: text
    huffman_encoded_value: bool
    ? value_length: uint32
    ? value: text
}
~~~
{: #insertwithoutnamereferenceinstruction-def
title="InsertWithoutNameReferenceInstruction definition"}

### DuplicateInstruction

~~~ cddl
DuplicateInstruction = {
    instruction_type: "duplicate"
    index: uint32
}
~~~
{: #duplicateinstruction-def
title="DuplicateInstruction definition"}

### SectionAcknowledgementInstruction

~~~ cddl
SectionAcknowledgementInstruction = {
    instruction_type: "section_acknowledgement"
    stream_id: uint64
}
~~~
{: #sectionacknowledgementinstruction-def
title="SectionAcknowledgementInstruction definition"}

### StreamCancellationInstruction

~~~ cddl
StreamCancellationInstruction = {
    instruction_type: "stream_cancellation"
    stream_id: uint64
}
~~~
{: #streamcancellationinstruction-def
title="StreamCancellationInstruction definition"}

### InsertCountIncrementInstruction

~~~ cddl
InsertCountIncrementInstruction = {
    instruction_type: "insert_count_increment"
    increment: uint32
}
~~~
{: #insertcountincrementinstruction-def
title="InsertCountIncrementInstruction definition"}

## QPACK Header compression

~~~ cddl
QPACKHeaderBlockRepresentation =  IndexedHeaderField /
                                  LiteralHeaderFieldWithName /
                                  LiteralHeaderFieldWithoutName
~~~
{: #qpackheaderblockrepresentation-def
title="QPACKHeaderBlockRepresentation definition"}

### IndexedHeaderField

Note: also used for "indexed header field with post-base index"

~~~ cddl
IndexedHeaderField = {
    header_field_type: "indexed_header"

    ; MUST be "dynamic" if is_post_base is true
    table_type: QPACKTableType
    index: uint32

    ; to represent the "indexed header field with post-base index"
    ; header field type
    is_post_base: bool .default false
}
~~~
{: #indexedheaderfield-def title="IndexedHeaderField definition"}

### LiteralHeaderFieldWithName

Note: also used for "Literal header field with post-base name reference"

~~~ cddl
LiteralHeaderFieldWithName = {
    header_field_type: "literal_with_name"

    ; the 3rd "N" bit
    preserve_literal: bool

    ; MUST be "dynamic" if is_post_base is true
    table_type: QPACKTableType
    name_index: uint32
    huffman_encoded_value: bool
    ? value_length: uint32
    ? value: text

    ; to represent the "indexed header field with post-base index"
    ; header field type
    is_post_base: bool .default false
}
~~~
{: #literalheaderfieldwithname-def
title="LiteralHeaderFieldWithName definition"}

### LiteralHeaderFieldWithoutName

~~~ cddl
LiteralHeaderFieldWithoutName = {
    header_field_type: "literal_without_name"

    ; the 3rd "N" bit
    preserve_literal: bool
    huffman_encoded_name: bool
    ? name_length: uint32
    ? name: text

    huffman_encoded_value: bool
    ? value_length: uint32
    ? value: text
}
~~~
{: #literalheaderfieldwithoutname-def
title="LiteralHeaderFieldWithoutName definition"}


### QPACKHeaderBlockPrefix

~~~ cddl
QPACKHeaderBlockPrefix = {
    required_insert_count: uint32
    sign_bit: bool
    delta_base: uint32
}
~~~
{: #qpackheaderblockprefix-def
title="QPACKHeaderBlockPrefix definition"}

### QPACKTableType

~~~ cddl
QPACKTableType = "static" / "dynamic"
~~~
{: #qpacktabletype-def title="QPACKTableType definition"}


# Change Log

## Since draft-ietf-quic-qlog-h3-events-02:

* TODO

## Since draft-ietf-quic-qlog-h3-events-01:

* No changes - new draft to prevent expiration

## Since draft-ietf-quic-qlog-h3-events-00:

* Change the data definition language from TypeScript to CDDL (#143)

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

