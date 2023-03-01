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
    org: Akamai
    email: rmarx@akamai.com
    role: editor
  -
    ins: L. Niccolini
    name: Luca Niccolini
    org: Meta
    email: lniccolini@meta.com
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


# HTTP/3 and QPACK Event Overview

This document defines events in two categories, written as lowercase to follow
convention: http ({{h3-ev}}) and qpack ({{qpack-ev}}).

As described in {{Section 3.4.2 of QLOG-MAIN}}, the qlog "name" field is the
concatenation of category and type.

{{h3-qpack-events}} summarizes the name value of each event type that is defined
in this specification.

| Name value                  | Importance |  Definition |
|:----------------------------|:-----------|:------------|
| h3:parameters_set           | Base       | {{h3-parametersset}} |
| h3:parameters_restored      | Base       | {{h3-parametersrestored}} |
| h3:stream_type_set          | Base       | {{h3-streamtypeset}} |
| h3:frame_created            | Core       | {{h3-framecreated}} |
| h3:frame_parsed             | Core       | {{h3-frameparsed}} |
| h3:push_resolved            | Extra      | {{h3-pushresolved}} |
| qpack:state_updated         | Base       | {{qpack-stateupdated}} |
| qpack:stream_state_updated  | Core       | {{qpack-streamstateupdate}} |
| qpack:dynamic_table_updated | Extra      | {{qpack-dynamictableupdate}} |
| qpack:headers_encoded       | Base       | {{qpack-headersencoded}} |
| qpack:headers_decoded       | Base       | {{qpack-headersdecoded}} |
| qpack:instruction_created   | Base       | {{qpack-instructioncreated}} |
| qpack:instruction_parsed    | Base       | {{qpack-instructionparsed}} |
{: #h3-qpack-events title="HTTP/3 and QPACK Events"}

# HTTP/3 Events {#h3-ev}

HTTP/3 events extend the `$ProtocolEventBody` extension point defined in {{QLOG-MAIN}}.

~~~ cddl
H3Events = H3ParametersSet / H3ParametersRestored /
             H3StreamTypeSet / H3FrameCreated /
             H3FrameParsed / H3PushResolved

$ProtocolEventBody /= H3Events
~~~
{: #h3events-def title="H3Events definition and ProtocolEventBody
extension"}

## parameters_set {#h3-parametersset}
Importance: Base

This event contains HTTP/3 and QPACK-level settings, mostly those received from
the HTTP/3 SETTINGS frame. All these parameters are typically set once and never
change. However, they are typically set at different times during the connection,
so there can be several instances of this event with different fields set.

Note that some settings have two variations (one set locally, one requested by the
remote peer). This is reflected in the "owner" field. As such, this field MUST be
correct for all settings included a single event instance. If you need to log
settings from two sides, you MUST emit two separate event instances.

Note: The CDDL unwrap operator (~) makes HTTPParameters into a re-usable list
of fields. The unwrap operator copies the fields from the referenced type into
the target type directly, extending the target with the unwrapped fields. TODO:
explain this better + provide reference and maybe an example.

Definition:

~~~ cddl
H3ParametersSet = {
    ? owner: Owner

    ~H3Parameters

    ; qlog-specific
    ; indicates whether this implementation waits for a SETTINGS
    ; frame before processing requests
    ? waits_for_settings: bool
}

H3Parameters = {
    ? max_header_list_size: uint64
    ? max_table_capacity: uint64
    ? blocked_streams_count: uint64

    ; additional settings for grease and extensions
    * text => uint64
}
~~~
{: #h3-parametersset-def title="H3ParametersSet definition"}

Note: enabling server push is not explicitly done in HTTP/3 by use of a setting or
parameter. Instead, it is communicated by use of the MAX_PUSH_ID frame, which
should be logged using the frame_created and frame_parsed events below.

Additionally, this event can contain any number of unspecified fields. This is to
reflect setting of for example unknown (greased) settings or parameters of
(proprietary) extensions.

## parameters_restored {#h3-parametersrestored}
Importance: Base

When using QUIC 0-RTT, HTTP/3 clients are expected to remember and reuse the
server's SETTINGs from the previous connection. This event is used to indicate
which HTTP/3 settings were restored and to which values when utilizing 0-RTT.

Definition:

~~~ cddl
H3ParametersRestored = {

    ~H3Parameters

}
~~~
{: #h3-parametersrestored-def title="H3ParametersRestored definition"}

Note that, like for parameters_set above, this event can contain any number of
unspecified fields to allow for additional and custom settings.

## stream_type_set {#h3-streamtypeset}
Importance: Base

Emitted when a stream's type becomes known. This is typically when a stream is
opened and the stream's type indicator is sent or received.

Note: most of this information can also be inferred by looking at a stream's id,
since id's are strictly partitioned at the QUIC level. Even so, this event has a
"Base" importance because it helps a lot in debugging to have this information
clearly spelled out.

Definition:

~~~ cddl
H3StreamTypeSet = {
    ? owner: Owner
    stream_id: uint64

    stream_type: H3StreamType

    ; only when stream_type === "unknown"
    ? raw_stream_type: uint64

    ; only when stream_type === "push"
    ? associated_push_id: uint64
}

H3StreamType =  "request" /
                  "control" /
                  "push" /
                  "reserved" /
                  "unknown" /
                  "qpack_encode" /
                  "qpack_decode"
~~~
{: #h3-streamtypeset-def title="H3StreamTypeSet definition"}

## frame_created {#h3-framecreated}
Importance: Core

HTTP equivalent to the packet_sent event. This event is emitted when the HTTP/3
framing actually happens. Note: this is not necessarily the same as when the
HTTP/3 data is passed on to the QUIC layer. For that, see the "data_moved" event
in {{QLOG-QUIC}}.

Definition:

~~~ cddl
H3FrameCreated = {
    stream_id: uint64
    ? length: uint64
    frame: $H3Frame
    ? raw: RawInfo
}
~~~
{: #h3-framecreated-def title="H3FrameCreated definition"}

Note: in HTTP/3, DATA frames can have arbitrarily large lengths to reduce frame
header overhead. As such, DATA frames can span many QUIC packets and can be
created in a streaming fashion. In this case, the frame_created event is emitted
once for the frame header, and further streamed data is indicated using the
data_moved event.

## frame_parsed {#h3-frameparsed}
Importance: Core

HTTP equivalent to the packet_received event. This event is emitted when the
HTTP/3 frame is parsed. Note: this is not necessarily the same as when the
HTTP/3 data is actually received on the QUIC layer. For that, see the
"data_moved" event in {{QLOG-QUIC}}.


Definition:

~~~ cddl
H3FrameParsed = {
    stream_id: uint64
    ? length: uint64
    frame: $H3Frame
    ? raw: RawInfo
}
~~~
{: #h3-frameparsed-def title="H3FrameParsed definition"}

Note: in HTTP/3, DATA frames can have arbitrarily large lengths to reduce frame
header overhead. As such, DATA frames can span many QUIC packets and can be
processed in a streaming fashion. In this case, the frame_parsed event is emitted
once for the frame header, and further streamed data is indicated using the
data_moved event.

## push_resolved {#h3-pushresolved}
Importance: Extra

This event is emitted when a pushed resource is successfully claimed (used) or,
conversely, abandoned (rejected) by the application on top of HTTP/3 (e.g., the
web browser). This event is added to help debug problems with unexpected PUSH
behaviour, which is commonplace with HTTP/2.

Definition:

~~~ cddl
H3PushResolved = {
    ? push_id: uint64

    ; in case this is logged from a place that does not have access
    ; to the push_id
    ? stream_id: uint64

    decision: H3PushDecision
}

H3PushDecision = "claimed" / "abandoned"
~~~
{: #h3-pushresolved-def title="H3PushResolved definition"}

# HTTP/3 Data Field Definitions

The following data field definitions can be used in HTTP/3 events.

## Owner

~~~ cddl
Owner = "local" / "remote"
~~~
{: #owner-def title="Owner definition"}

## H3Frame

The generic `$H3Frame` is defined here as a CDDL extension point (a "socket"
or "plug"). It can be extended to support additional HTTP/3 frame types.

~~~ cddl
; The H3Frame is any key-value map (e.g., JSON object)
$H3Frame /= {
    * text => any
}
~~~
{: #h3frame-def title="H3Frame plug definition"}

The HTTP/3 frame types defined in this document are as follows:

~~~ cddl
H3BaseFrames =  H3DataFrame /
             H3HeadersFrame /
             H3CancelPushFrame /
             H3SettingsFrame /
             H3PushPromiseFrame /
             H3GoawayFrame /
             H3MaxPushIDFrame /
             H3ReservedFrame /
             H3UnknownFrame

$H3Frame /= H3BaseFrames
~~~
{: #h3baseframe-def title="H3BaseFrames definition"}

### H3DataFrame
~~~ cddl
H3DataFrame = {
    frame_type: "data"
    ? raw: hexstring
}
~~~
{: #h3dataframe-def title="H3DataFrame definition"}

### H3HeadersFrame

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
{: #h3-headersframe-ex title="H3HeadersFrame example"}

~~~ cddl
H3HeadersFrame = {
    frame_type: "headers"
    headers: [* H3HTTPField]
}
~~~
{: #h3-headersframe-def title="H3HeadersFrame definition"}

~~~ cddl
H3HTTPField = {
    name: text
    value: text
}
~~~
{: #httpfield-def title="HTTPField definition"}

### H3CancelPushFrame

~~~ cddl
H3CancelPushFrame = {
    frame_type: "cancel_push"
    push_id: uint64
}
~~~
{: #h3-cancelpushframe-def title="H3CancelPushFrame definition"}

### H3SettingsFrame

~~~ cddl
H3SettingsFrame = {
    frame_type: "settings"
    settings: [* H3Setting]
}

H3Setting = {
    name: text
    value: uint64
}
~~~
{: #h3settingsframe-def title="H3SettingsFrame definition"}

### H3PushPromiseFrame

~~~ cddl
H3PushPromiseFrame = {
    frame_type: "push_promise"
    push_id: uint64
    headers: [* HTTPField]
}
~~~
{: #h3pushpromiseframe-def title="H3PushPromiseFrame definition"}

### H3GoAwayFrame

~~~ cddl
H3GoawayFrame = {
    frame_type: "goaway"

    ; Either stream_id or push_id.
    ; This is implicit from the sender of the frame
    id: uint64
}
~~~
{: #h3goawayframe-def title="H3GoawayFrame definition"}

### H3MaxPushIDFrame

~~~ cddl
H3MaxPushIDFrame = {
    frame_type: "max_push_id"
    push_id: uint64
}
~~~
{: #h3maxpushidframe-def title="H3MaxPushIDFrame definition"}

### H3ReservedFrame

~~~ cddl
H3ReservedFrame = {
    frame_type: "reserved"

    ? length: uint64
}
~~~
{: #h3reservedframe-def title="H3ReservedFrame definition"}

### H3UnknownFrame

~~~ cddl
H3UnknownFrame = {
    frame_type: "unknown"
    raw_frame_type: uint64

    ? raw_length: uint32
    ? raw: hexstring
}
~~~
{: #h3unknownframe-def title="UnknownFrame definition"}

### H3ApplicationError

~~~ cddl
H3ApplicationError =  "http_no_error" /
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
{: #h3applicationerror-def title="H3ApplicationError definition"}

The H3ApplicationError defines the general $ApplicationError
definition in the qlog QUIC definition, see {{QLOG-QUIC}}.

~~~ cddl
; ensure HTTP errors are properly validate in QUIC events as well
; e.g., QUIC's ConnectionClose Frame
$ApplicationError /= H3ApplicationError
~~~

# QPACK Events {#qpack-ev}

QPACK events extend the `$ProtocolEventBody` extension point defined in
{{QLOG-MAIN}}.

~~~ cddl
QPACKEvents = QPACKStateUpdate / QPACKStreamStateUpdate /
              QPACKDynamicTableUpdate / QPACKHeadersEncoded /
              QPACKHeadersDecoded / QPACKInstructionCreated /
              QPACKInstructionParsed

$ProtocolEventBody /= QPACKEvents
~~~
{: #qpackevents-def title="QPACKEvents definition and ProtocolEventBody
extension"}

QPACK events mainly serve as an aid to debug low-level QPACK issues.The
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

# QPACK Data Field Definitions

The following data field definitions can be used in QPACK events.

## QPACKInstruction

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

## QPACKHeaderBlockRepresentation

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


## QPACKHeaderBlockPrefix

~~~ cddl
QPACKHeaderBlockPrefix = {
    required_insert_count: uint32
    sign_bit: bool
    delta_base: uint32
}
~~~
{: #qpackheaderblockprefix-def
title="QPACKHeaderBlockPrefix definition"}

## QPACKTableType

~~~ cddl
QPACKTableType = "static" / "dynamic"
~~~
{: #qpacktabletype-def title="QPACKTableType definition"}

# Security and Privacy Considerations

The security and privacy considerations discussed in {{QLOG-MAIN}} apply to this
document as well.

# IANA Considerations

TBD

--- back


# Change Log

## Since draft-ietf-quic-qlog-h3-events-02:

* Renamed HTTPStreamType data to request (#222)
* Added HTTPStreamType value unknown (#227)
* Added HTTPUnknownFrame (#224)
* Replaced old and new fields with stream_type in HTTPStreamTypeSet (#240)
* Changed HTTPFrame to a CDDL plug type (#257)
* Moved data definitions out of the appendix into separate sections
* Added overview Table of Contents

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

# Acknowledgements
{:numbered="false"}

Much of the initial work by Robin Marx was done at the Hasselt and KU Leuven
Universities.

Thanks to Jana Iyengar, Brian Trammell, Dmitri Tikhonov, Stephen Petrides, Jari
Arkko, Marcus Ihlar, Victor Vasiliev, Mirja Kühlewind, Jeremy Lainé, Kazu
Yamamoto, and Christian Huitema for their feedback and suggestions.

