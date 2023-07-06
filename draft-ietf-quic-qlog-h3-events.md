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
"data" fields and their semantics for the HTTP/3 protocol {{!HTTP3=RFC9114}},
QPACK {{!QPACK=RFC9204}}, and some of their extensions (see
{{!EXTENDED-CONNECT=RFC9220}} and {{!H3-DATAGRAM=RFC9297}}).

It also describes events for {{!H3_PRIORITIZATION=RFC9218}} (TODO: change this
once #310 is merged!).

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

# HTTP/3 and QPACK Event Overview

This document defines events in two categories, written as lowercase to follow
convention: h3 ({{h3-ev}}) and qpack ({{qpack-ev}}).

As described in {{Section 3.4.2 of QLOG-MAIN}}, the qlog "name" field is the
concatenation of category and type.

{{h3-qpack-events}} summarizes the name value of each event type that is defined
in this specification.

| Name value                  | Importance |  Definition |
|:----------------------------|:-----------|:------------|
| h3:parameters_set         | Base       | {{h3-parametersset}} |
| h3:parameters_restored    | Base       | {{h3-parametersrestored}} |
| h3:stream_type_set        | Base       | {{h3-streamtypeset}} |
| h3:priority_updated       | Base       | {{h3-priorityupdated}} |
| h3:frame_created          | Core       | {{h3-framecreated}} |
| h3:frame_parsed           | Core       | {{h3-frameparsed}} |
| h3:datagram_created       | Base       | {{h3-datagramcreated}} |
| h3:datagram_parsed        | Base       | {{h3-datagramparsed}} |
| h3:push_resolved          | Extra      | {{h3-pushresolved}} |
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
H3Events = H3ParametersSet /
           H3ParametersRestored /
           H3StreamTypeSet /
           H3PriorityUpdated /
           H3FrameCreated /
           H3FrameParsed /
           H3DatagramCreated /
           H3DatagramParsed /
           H3PushResolved

$ProtocolEventBody /= H3Events
~~~
{: #h3-events-def title="H3Events definition and ProtocolEventBody
extension"}

HTTP events are logged when a certain condition happens at the application
layer, and there isn't always a one to one mapping between HTTP and QUIC events.
The exchange of data between the HTTP and QUIC layer is logged via the
"stream_data_moved" and "datagram_data_moved" events in {{QLOG-QUIC}}.

## parameters_set {#h3-parametersset}
Importance: Base

This event contains HTTP/3 and QPACK-level settings, mostly those received from
the HTTP/3 SETTINGS frame. All these parameters are typically set once and never
change. However, they are typically set at different times during the connection,
so there can be several instances of this event with different fields set.

The "owner" field reflects how Settings are exchanged on a connection. Sent
settings have the value "local" and received settings have the value
"received". A qlog can have multiple instances of this event.

As a reminder the CDDL unwrap operator (~), see {{?RFC8610}}), copies the fields
from the referenced type (H3Parameters) into the target type directly, extending the
target with the unwrapped fields.

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
    ; RFC9114
    ? max_field_section_size: uint64

    ; RFC9204
    ? max_table_capacity: uint64
    ? blocked_streams_count: uint64

    ; RFC9220 (SETTINGS_ENABLE_CONNECT_PROTOCOL)
    ? extended_connect: uint16

    ; RFC9297 (SETTINGS_H3_DATAGRAM)
    ? h3_datagram: uint16

    ; additional settings for grease and extensions
    * text => uint64
}
~~~
{: #h3-parametersset-def title="H3ParametersSet definition"}

This event can contain any number of unspecified fields. This allows for
representation of reserved settings (aka GREASE) or ad-hoc support for
extension settings that do not have a related qlog schema definition.

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

Similar to H3ParametersSet this event can contain any number of unspecified
fields to allow for reserved or extension settings.

## stream_type_set {#h3-streamtypeset}
Importance: Base

Emitted when a stream's type becomes known. This is typically when a stream is
opened and the stream's type indicator is sent or received.

The stream_type_value field is the numerical value without VLIE encoding.

Definition:

~~~ cddl
H3StreamTypeSet = {
    ? owner: Owner
    stream_id: uint64
    stream_type: H3StreamType

    ; only when stream_type === "unknown"
    ? stream_type_value: uint64

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

## priority_updated {#h3-priorityupdated}
Importance: Base

Emitted when the priority of a request stream or push stream is initialized or
updated through mechanisms defined in {{!RFC9218}}. For example, the priority
can be updated through signals received from client and/or server (e.g., in
HTTP/3 HEADERS or PRIORITY_UPDATE frames) or it can be changed or overridden due
to local policies.

Definition:

~~~ cddl
H3PriorityUpdated = {
    ; if the prioritized element is a request stream
    ? stream_id: uint64

    ; if the prioritized element is a push stream
    ? push_id: uint64

    ? old: H3Priority
    new: H3Priority
}
~~~
{: #h3-priorityupdated-def title="H3PriorityUpdated definition"}

## frame_created {#h3-framecreated}
Importance: Core

This event is emitted when the HTTP/3 framing actually happens. This does not
necessarily coincide with HTTP/3 data getting passed to the QUIC layer. For
that, see the "stream_data_moved" event in {{QLOG-QUIC}}.

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

## frame_parsed {#h3-frameparsed}
Importance: Core

This event is emitted when the HTTP/3 frame is parsed. This is not
necessarily the same as when the HTTP/3 data is actually received on the QUIC
layer. For that, see the "stream_data_moved" event in {{QLOG-QUIC}}.

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

HTTP/3 DATA frames can have arbitrarily large lengths to reduce frame header
overhead. As such, DATA frames can span multiple QUIC packets. In this case, the
frame_parsed event is emitted once for the frame header, and further streamed
data is indicated using the stream_data_moved event.

## datagram_created {#h3-datagramcreated}
Importance: Base

This event is emitted when an HTTP/3 Datagram is created (see {{!RFC9297}}).
This does not necessarily coincide with the HTTP/3 Datagram getting passed to
the QUIC layer. For that, see the "datagram_data_moved" event in {{QLOG-QUIC}}.

Definition:

~~~ cddl
H3DatagramCreated = {
    quarter_stream_id: uint64
    ? datagram: $H3Datagram
    ? raw: RawInfo
}
~~~
{: #h3-datagramcreated-def title="H3DatagramCreated definition"}

## datagram_parsed {#h3-datagramparsed}
Importance: Base

This event is emitted when the HTTP/3 Datagram is parsed (see {{!RFC9297}}).
This is not necessarily the same as when the HTTP/3 Datagram is actually
received on the QUIC layer. For that, see the "datagram_data_moved" event in
{{QLOG-QUIC}}.

Definition:

~~~ cddl
H3DatagramParsed = {
    quarter_stream_id: uint64
    ? datagram: $H3Datagram
    ? raw: RawInfo
}
~~~
{: #h3-datagramparsed-def title="H3DatagramParsed definition"}

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

H3PushDecision = "claimed" /
                   "abandoned"
~~~
{: #h3-pushresolved-def title="H3PushResolved definition"}

# HTTP/3 Data Field Definitions

The following data field definitions can be used in HTTP/3 events.

## Owner

~~~ cddl
Owner = "local" /
        "remote"
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
{: #h3-frame-def title="H3Frame plug definition"}

The HTTP/3 frame types defined in this document are as follows:

~~~ cddl
H3BaseFrames = H3DataFrame /
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

## H3Datagram

The generic `$H3Datagram` is defined here as a CDDL extension point (a "socket"
or "plug"). It can be extended to support additional HTTP/3 datagram types. This
document intentionally does not define any specific HTTP/3 Datagram types.

~~~ cddl
; The H3Datagram is any key-value map (e.g., JSON object)
$H3Datagram /= {
    * text => any
}
~~~
{: #h3-datagram-def title="H3Datagram plug definition"}

### H3DataFrame

~~~ cddl
H3DataFrame = {
    frame_type: "data"
    ? raw: RawInfo
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
    ? value: text
}
~~~
{: #h3field-def title="H3HTTPField definition"}

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
    headers: [* H3HTTPField]
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

### H3PriorityUpdateFrame

The PRIORITY_UPDATE frame is defined in {{!RFC9218}}.

~~~ cddl
H3PriorityUpdateFrame = {
    frame_type: "priority_update"

    ; if the prioritized element is a request stream
    ? stream_id: uint64

    ; if the prioritized element is a push stream
    ? push_id: uint64

    priority_field_value: H3Priority
}

; The priority value in ASCII text, encoded using Structured Fields
; Example: u=5, i
H3Priority = text
~~~
{: #h3priorityupdateframe-def title="h3priorityupdateframe definition"}

### H3ReservedFrame

~~~ cddl
H3ReservedFrame = {
    frame_type: "reserved"
    ? length: uint64
}
~~~
{: #h3reservedframe-def title="H3ReservedFrame definition"}

### H3UnknownFrame

The frame_type_value field is the numerical value without VLIE encoding.

~~~ cddl
H3UnknownFrame = {
    frame_type: "unknown"
    frame_type_value: uint64
    ? raw: RawInfo
}
~~~
{: #h3unknownframe-def title="UnknownFrame definition"}

### H3ApplicationError

~~~ cddl
H3ApplicationError = "http_no_error" /
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
{: #h3-applicationerror-def title="H3ApplicationError definition"}

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
QPACKEvents = QPACKStateUpdate /
              QPACKStreamStateUpdate /
              QPACKDynamicTableUpdate /
              QPACKHeadersEncoded /
              QPACKHeadersDecoded /
              QPACKInstructionCreated /
              QPACKInstructionParsed

$ProtocolEventBody /= QPACKEvents
~~~
{: #qpackevents-def title="QPACKEvents definition and ProtocolEventBody
extension"}

QPACK events mainly serve as an aid to debug low-level QPACK issues.The
higher-level, plaintext header values SHOULD (also) be logged in the
http.frame_created and http.frame_parsed event data (instead).

QPACK does not have its own parameters_set event. This was merged with
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

This event is of "Core" importance, as it might have a large impact on
HTTP/3's observed performance.

Definition:

~~~ cddl
QPACKStreamStateUpdate = {
    stream_id: uint64

    ; streams are assumed to start "unblocked"
    ; until they become "blocked"
    state: QPACKStreamState
}

QPACKStreamState = "blocked" /
                   "unblocked"
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

QPACKDynamicTableUpdateType = "inserted" /
                              "evicted"

QPACKDynamicTableEntry = {
    index: uint64
    ? name: text /
            hexstring
    ? value: text /
             hexstring
}
~~~
{: #qpack-dynamictableupdate-def title="QPACKDynamicTableUpdate definition"}

## headers_encoded {#qpack-headersencoded}
Importance: Base

This event is emitted when an uncompressed header block is encoded successfully.

This event has overlap with http.frame_created for the HeadersFrame type.
When outputting both events, implementers MAY omit the "headers" field in this
event.

Definition:

~~~ cddl
QPACKHeadersEncoded = {
    ? stream_id: uint64
    ? headers: [+ H3HTTPField]
    block_prefix: QPACKHeaderBlockPrefix
    header_block: [+ QPACKHeaderBlockRepresentation]
    ? raw: RawInfo
}
~~~
{: #qpack-headersencoded-def title="QPACKHeadersEncoded definition"}

## headers_decoded {#qpack-headersdecoded}
Importance: Base

This event is emitted when a compressed header block is decoded successfully.

This event has overlap with http.frame_parsed for the HeadersFrame type.
When outputting both events, implementers MAY omit the "headers" field in this
event.

Definition:

~~~ cddl
QPACKHeadersDecoded = {
    ? stream_id: uint64
    ? headers: [+ H3HTTPField]
    block_prefix: QPACKHeaderBlockPrefix
    header_block: [+ QPACKHeaderBlockRepresentation]
    ? raw: RawInfo
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
    ? raw: RawInfo
}
~~~
{: #qpack-instructioncreated-def title="QPACKInstructionCreated definition"}

Encoder/decoder semantics and stream_id's are implicit in either the
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
    ? raw: RawInfo
}
~~~
{: #qpack-instructionparsed-def title="QPACKInstructionParsed definition"}

Encoder/decoder semantics and stream_id's are implicit in either the
instruction types or can be logged via other events (e.g., http.stream_type_set)

# QPACK Data Field Definitions

The following data field definitions can be used in QPACK events.

## QPACKInstruction

The instructions do not have explicit encoder/decoder types, since there is
no overlap between the instructions of both types in neither name nor function.

~~~ cddl
QPACKInstruction = SetDynamicTableCapacityInstruction /
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
QPACKHeaderBlockRepresentation = IndexedHeaderField /
                                 LiteralHeaderFieldWithName /
                                 LiteralHeaderFieldWithoutName
~~~
{: #qpackheaderblockrepresentation-def
title="QPACKHeaderBlockRepresentation definition"}

### IndexedHeaderField

This is also used for "indexed header field with post-base index"

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

This is also used for "Literal header field with post-base name reference".

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
QPACKTableType = "static" /
                 "dynamic"
~~~
{: #qpacktabletype-def title="QPACKTableType definition"}

# Security and Privacy Considerations

The security and privacy considerations discussed in {{QLOG-MAIN}} apply to this
document as well.

# IANA Considerations

TBD

--- back

# Change Log

## Since draft-ietf-quic-qlog-h3-events-03:

* Ensured consistent use of RawInfo to indicate raw wire bytes (#243)
* Changed HTTPStreamTypeSet:raw_stream_type to stream_type_value (#54)
* Changed HTTPUnknownFrame:raw_frame_type to frame_type_value (#54)
* Renamed max_header_list_size to max_field_section_size (#282)

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

