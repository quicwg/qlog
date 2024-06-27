---
title: HTTP/3 qlog event definitions
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
    email: martenseemann@gmail.com
    role: editor
  - ins: L. Pardue
    name: Lucas Pardue
    org: Cloudflare
    email: lucas@lucaspardue.com
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
HTTP/3-related events. These events can then be embedded in the higher
level schema defined in {{QLOG-MAIN}}.

--- note_Note_to_Readers

> Note to RFC editor: Please remove this section before publication.

Feedback and discussion are welcome at
[https://github.com/quicwg/qlog](https://github.com/quicwg/qlog). Readers are
advised to refer to the "editor's draft" at that URL for an up-to-date version
of this document.

Concrete examples of integrations of this schema in
various programming languages can be found at
[https://github.com/quiclog/qlog/](https://github.com/quiclog/qlog/).

--- middle

# Introduction

This document describes the values of the qlog name ("category" + "event") and
"data" fields and their semantics for the HTTP/3 protocol {{RFC9114}} and some
of extensions (see {{!EXTENDED-CONNECT=RFC9220}}, {{!H3_PRIORITIZATION=RFC9218}}
and {{!H3-DATAGRAM=RFC9297}}).

## Notational Conventions

{::boilerplate bcp14-tagged}

The event and data structure definitions in ths document are expressed
in the Concise Data Definition Language {{!CDDL=RFC8610}} and its
extensions described in {{QLOG-MAIN}}.

The following fields from {{QLOG-MAIN}} are imported and used: name, category,
type, data, group_id, protocol_type, importance, RawInfo, and time-related
fields.

As is the case for {{QLOG-MAIN}}, the qlog schema definitions in this document
are intentionally agnostic to serialization formats. The choice of format is an
implementation decision.

# Overview

This document describes how HTTP/3 can be expressed in qlog using the schema
defined in {{QLOG-MAIN}}. HTTP/3 events are defined with a category, a name (the
concatenation of "category" and "event"), an "importance", an optional
"trigger", and "data" fields.

Some data fields use complex datastructures. These are represented as enums or
re-usable definitions, which are grouped together on the bottom of this document
for clarity.

When any event from this document is included in a qlog trace, the
"protocol_type" qlog array field MUST contain an entry with the value "HTTP3":

~~~ cddl
$ProtocolType /= "HTTP3"
~~~
{: #protocoltype-extension-h3 title="ProtocolType extension for HTTP/3"}

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

# HTTP/3 Event Overview

This document defines events in two categories, written as lowercase to follow
convention: h3 ({{h3-ev}}).

As described in {{Section 3.4.2 of QLOG-MAIN}}, the qlog "name" field is the
concatenation of category and type.

{{h3-events}} summarizes the name value of each event type that is defined
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
{: #h3-events title="HTTP/3 Events"}

# HTTP/3 Events {#h3-ev}

HTTP/3 events extend the `$ProtocolEventData` extension point defined in
{{QLOG-MAIN}}. Additionally, they allow for direct extensibility by their use of
per-event extension points via the `$$` CDDL "group socket" syntax, as also
described in {{QLOG-MAIN}}.

~~~ cddl
H3EventData = H3ParametersSet /
              H3ParametersRestored /
              H3StreamTypeSet /
              H3PriorityUpdated /
              H3FrameCreated /
              H3FrameParsed /
              H3DatagramCreated /
              H3DatagramParsed /
              H3PushResolved

$ProtocolEventData /= H3EventData
~~~
{: #h3-events-def title="H3EventData definition and ProtocolEventData
extension"}

HTTP events are logged when a certain condition happens at the application
layer, and there isn't always a one to one mapping between HTTP and QUIC events.
The exchange of data between the HTTP and QUIC layer is logged via the
"stream_data_moved" and "datagram_data_moved" events in {{QLOG-QUIC}}.

HTTP/3 frames are transmitted on QUIC streams, which allows them to span
multiple QUIC packets. Some implementations might send a single large frame,
rather than a sequence of smaller frames, in order to amortize frame header
overhead. HTTP/3 frame headers are represented by the frame_created
({{h3-framecreated}}) and frame_parsed ({{h3-frameparsed}}) events. Subsequent
frame payload data transfer is indicated by stream_data_moved events.
Furthermore, stream_data_moved events can appear before frame_parsed events
because implementations need to read data from a stream in order to parse the
frame header.

## parameters_set {#h3-parametersset}

The `parameters_set` event contains HTTP/3 and QPACK-level settings, mostly
those received from the HTTP/3 SETTINGS frame. It has Base importance level; see
{{Section 9.2 of QLOG-MAIN}}.

All these parameters are typically set once and never change. However, they
might be set at different times during the connection, therefore a qlog can have
multiple instances of `parameters_set` with different fields set.

The "owner" field reflects how Settings are exchanged on a connection. Sent
settings have the value "local" and received settings have the value
"received".

~~~ cddl
H3ParametersSet = {
    ? owner: Owner

    ; RFC9114
    ? max_field_section_size: uint64

    ; RFC9204
    ? max_table_capacity: uint64
    ? blocked_streams_count: uint64

    ; RFC9220 (SETTINGS_ENABLE_CONNECT_PROTOCOL)
    ? extended_connect: uint16

    ; RFC9297 (SETTINGS_H3_DATAGRAM)
    ? h3_datagram: uint16

    ; qlog-specific
    ; indicates whether this implementation waits for a SETTINGS
    ; frame before processing requests
    ? waits_for_settings: bool

    * $$h3-parametersset-extension
}
~~~
{: #h3-parametersset-def title="H3ParametersSet definition"}

The `parameters_set` event can contain any number of unspecified fields. This
allows for representation of reserved settings (aka GREASE) or ad-hoc support
for extension settings that do not have a related qlog schema definition.

## parameters_restored {#h3-parametersrestored}

When using QUIC 0-RTT, HTTP/3 clients are expected to remember and reuse the
server's SETTINGs from the previous connection. The `parameters_restored` event
is used to indicate which HTTP/3 settings were restored and to which values when
utilizing 0-RTT. It has Base importance level; see {{Section 9.2 of QLOG-MAIN}}.

~~~ cddl
H3ParametersRestored = {
    ; RFC9114
    ? max_field_section_size: uint64

    ; RFC9204
    ? max_table_capacity: uint64
    ? blocked_streams_count: uint64

    ; RFC9220 (SETTINGS_ENABLE_CONNECT_PROTOCOL)
    ? extended_connect: uint16

    ; RFC9297 (SETTINGS_H3_DATAGRAM)
    ? h3_datagram: uint16

    * $$h3-parametersrestored-extension
}
~~~
{: #h3-parametersrestored-def title="H3ParametersRestored definition"}

## stream_type_set {#h3-streamtypeset}

The `stream_type_set` event conveys when a HTTP/3 stream type becomes known; see
{{Sections 6.1 and 6.2 of RFC9114}}. It has Base importance level; see {{Section
9.2 of QLOG-MAIN}}.

Client bidirectional streams always have a stream_type value of "request".
Server bidirectional streams have no defined use, although extensions could
change that.

Unidirectional streams in either direction begin with with a variable-length
integer type. Where the type is not known, the stream_type value of "unknown"
type can be used and the value captured in the stream_type_bytes field; a
numerical value without variable-length integer encoding.

The generic `$H3StreamType` is defined here as a CDDL "type socket" extension
point. It can be extended to support additional HTTP/3 stream types.

~~~ cddl
H3StreamTypeSet = {
    ? owner: Owner
    stream_id: uint64
    stream_type: $H3StreamType

    ; only when stream_type === "unknown"
    ? stream_type_bytes: uint64

    ; only when stream_type === "push"
    ? associated_push_id: uint64

    * $$h3-streamtypeset-extension
}

$H3StreamType /=  "request" /
                  "control" /
                  "push" /
                  "reserved" /
                  "unknown" /
                  "qpack_encode" /
                  "qpack_decode"
~~~
{: #h3-streamtypeset-def title="H3StreamTypeSet definition"}

## priority_updated {#h3-priorityupdated}

Emitted when the priority of a request stream or push stream is initialized or
updated through mechanisms defined in {{!RFC9218}}. For example, the priority
can be updated through signals received from client and/or server (e.g., in
HTTP/3 HEADERS or PRIORITY_UPDATE frames) or it can be changed or overridden due
to local policies. The event has Base importance level; see {{Section 9.2 of
QLOG-MAIN}}.

~~~ cddl
H3PriorityUpdated = {
    ; if the prioritized element is a request stream
    ? stream_id: uint64

    ; if the prioritized element is a push stream
    ? push_id: uint64

    ? old: H3Priority
    new: H3Priority

    * $$h3-priorityupdated-extension
}
~~~
{: #h3-priorityupdated-def title="H3PriorityUpdated definition"}

## frame_created {#h3-framecreated}

The `frame_created` event is emitted when the HTTP/3 framing actually happens.
It has Core importance level; see {{Section 9.2 of QLOG-MAIN}}.

This event does not necessarily coincide with HTTP/3 data getting passed to the
QUIC layer. For that, see the `stream_data_moved` event in {{QLOG-QUIC}}.

~~~ cddl
H3FrameCreated = {
    stream_id: uint64
    ? length: uint64
    frame: $H3Frame
    ? raw: RawInfo

    * $$h3-framecreated-extension
}
~~~
{: #h3-framecreated-def title="H3FrameCreated definition"}

## frame_parsed {#h3-frameparsed}

The `frame_parsed` event is emitted when the HTTP/3 frame is parsed. It has Core
importance level; see {{Section 9.2 of QLOG-MAIN}}.

This event is not necessarily the same as when the HTTP/3 data is actually
received on the QUIC layer. For that, see the `stream_data_moved` event in
{{QLOG-QUIC}}.

~~~ cddl
H3FrameParsed = {
    stream_id: uint64
    ? length: uint64
    frame: $H3Frame
    ? raw: RawInfo

    * $$h3-frameparsed-extension
}
~~~
{: #h3-frameparsed-def title="H3FrameParsed definition"}


## datagram_created {#h3-datagramcreated}

The `datagram_created` event is emitted when an HTTP/3 Datagram is created (see
{{!RFC9297}}). It has Base importance level; see {{Section 9.2 of QLOG-MAIN}}.

This event does not necessarily coincide with the HTTP/3 Datagram getting passed
to the QUIC layer. For that, see the `datagram_data_moved` event in
{{QLOG-QUIC}}.

~~~ cddl
H3DatagramCreated = {
    quarter_stream_id: uint64
    ? datagram: $H3Datagram
    ? raw: RawInfo

    * $$h3-datagramcreated-extension
}
~~~
{: #h3-datagramcreated-def title="H3DatagramCreated definition"}

## datagram_parsed {#h3-datagramparsed}

The `datagram_parsed` event is emitted when the HTTP/3 Datagram is parsed (see
{{!RFC9297}}). It has Base importance level; see {{Section 9.2 of QLOG-MAIN}}.

This event is not necessarily the same as when the HTTP/3 Datagram is actually
received on the QUIC layer. For that, see the `datagram_data_moved` event in
{{QLOG-QUIC}}.

~~~ cddl
H3DatagramParsed = {
    quarter_stream_id: uint64
    ? datagram: $H3Datagram
    ? raw: RawInfo

    * $$h3-datagramparsed-extension
}
~~~
{: #h3-datagramparsed-def title="H3DatagramParsed definition"}

## push_resolved {#h3-pushresolved}

The `push_resolved` event is emitted when a pushed resource ({{Section 4.6 of
RFC9114}}) is successfully claimed (used) or, conversely, abandoned (rejected)
by the application on top of HTTP/3 (e.g., the web browser). This event provides
additional context that can is aid debugging issues related to server push. It
has Extra importance level; see {{Section 9.2 of QLOG-MAIN}}.

~~~ cddl
H3PushResolved = {
    ? push_id: uint64

    ; in case this is logged from a place that does not have access
    ; to the push_id
    ? stream_id: uint64
    decision: H3PushDecision

    * $$h3-pushresolved-extension
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

The generic `$H3Frame` is defined here as a CDDL "type socket" extension point.
It can be extended to support additional HTTP/3 frame types.

~~~~~~
; The H3Frame is any key-value map (e.g., JSON object)
$H3Frame /= {
    * text => any
}
~~~~~~
{: #h3-frame-def title="H3Frame type socket definition"}

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

The generic `$H3Datagram` is defined here as a CDDL "type socket" extension
point. It can be extended to support additional HTTP/3 datagram types. This
document intentionally does not define any specific qlog schemas for specific
HTTP/3 Datagram types.

~~~~~~
; The H3Datagram is any key-value map (e.g., JSON object)
$H3Datagram /= {
    * text => any
}
~~~~~~
{: #h3-datagram-def title="H3Datagram type socket definition"}

### H3DataFrame

~~~ cddl
H3DataFrame = {
    frame_type: "data"
    ? raw: RawInfo
}
~~~
{: #h3dataframe-def title="H3DataFrame definition"}

### H3HeadersFrame

The payload of an HTTP/3 HEADERS frame is the QPACK-encoding of an HTTP field
section; see {{Section 7.2.2 of RFC9114}}. `H3HeaderFrame`, in contrast,
contains the HTTP field section without QPACK encoding.

~~~ cddl
H3HTTPField = {
    ? name: text
    ? name_bytes: hexstring
    ? value: text
    ? value_bytes: hexstring
}
~~~
{: #h3field-def title="H3HTTPField definition"}

~~~ cddl
H3HeadersFrame = {
    frame_type: "headers"
    headers: [* H3HTTPField]
}
~~~
{: #h3-headersframe-def title="H3HeadersFrame definition"}

For example, the HTTP field section

~~~
:path: value
:method: GET
:authority: example.org
:scheme: https
~~~

would be represented in a JSON serialization as:

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
    "value": "example.org"
  },
  {
    "name": ":scheme",
    "value": "https"
  }
]
~~~
{: #h3-headersframe-ex title="H3HeadersFrame example"}

{{Section 4.2 of RFC9114}} and {{Section 5.1 of RFC 9110}} define rules for the
characters used in HTTP field sections names and values. Characters outside the
range are invalid and result in the message being treated as malformed.

It is useful to log HTTP fields that are valid or invalid. Characters in the
allowed range can be safely logged by the text type used in the `name` and
`value` fields of `H3HTTPField`. Characters outside the range are unsafe for the
text type and need to be logged using the `name_bytes` and `value_bytes` field.
An instance of `H3HTTPField` MUST include either the `name` or `name_bytes`
field and MAY include both. An `H3HTTPField` MAY include a `value` or
`value_bytes` field or neither.

### H3CancelPushFrame

~~~ cddl
H3CancelPushFrame = {
    frame_type: "cancel_push"
    push_id: uint64
}
~~~
{: #h3-cancelpushframe-def title="H3CancelPushFrame definition"}

### H3SettingsFrame

The settings field can contain zero or more entries. Each setting has a name
field, which corresponds to Setting Name as defined (or as would be defined if
registered) in the "HTTP/3 Settings" registry maintained at
<https://www.iana.org/assignments/http3-parameters>.

An endpoint that receives unknown settings is not able to log a specific name.
Instead, the name value of "unknown" can be used and the value captured in the
`name_bytes` field; a numerical value without variable-length integer encoding.

~~~ cddl
H3SettingsFrame = {
    frame_type: "settings"
    settings: [* H3Setting]
}

H3Setting = {
    ? name: $H3SettingsName
    ; only when name === "unknown"
    ? name_bytes: uint64

    value: uint64
}

$H3SettingsName /= "settings_qpack_max_table_capacity" /
                   "settings_max_field_section_size" /
                   "settings_qpack_blocked_streams" /
                   "settings_enable_connect_protocol" /
                   "settings_h3_datagram" /
                   "reserved" /
                   "unknown"
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

The frame_type_bytes field is the numerical value without variable-length
integer encoding.

~~~ cddl
H3UnknownFrame = {
    frame_type: "unknown"
    frame_type_bytes: uint64
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

The H3ApplicationError extends the general $ApplicationError
definition in the qlog QUIC document, see {{QLOG-QUIC}}.

~~~ cddl
; ensure HTTP errors are properly validated in QUIC events as well
; e.g., QUIC's ConnectionClose Frame
$ApplicationError /= H3ApplicationError
~~~

# Security and Privacy Considerations

The security and privacy considerations discussed in {{QLOG-MAIN}} apply to this
document as well.

# IANA Considerations

There are no IANA considerations.

--- back

# Acknowledgements
{:numbered="false"}

Much of the initial work by Robin Marx was done at the Hasselt and KU Leuven
Universities.

Thanks to Jana Iyengar, Brian Trammell, Dmitri Tikhonov, Stephen Petrides, Jari
Arkko, Marcus Ihlar, Victor Vasiliev, Mirja Kühlewind, Jeremy Lainé, Kazu
Yamamoto, Christian Huitema and Hugo Landau for their feedback and suggestions.

# Change Log
{:numbered="false" removeinrfc="true"}

## Since draft-ietf-quic-qlog-h3-events-06:
{:numbered="false"}

* ProtocolEventBody is now called ProtocolEventData (#352)
* Editorial changes (#402)

## Since draft-ietf-quic-qlog-h3-events-05:
{:numbered="false"}

* Removed all qpack event definitions (#335)
* Various editorial changes

## Since draft-ietf-quic-qlog-h3-events-04:
{:numbered="false"}

* Renamed 'http' category to 'h3' (#300)
* H3HTTPField.value is now optional (#296)
* Added definitions for RFC9297 (HTTP/3 Datagram extension) (#310)
* Added definitions for RFC9218 (HTTP Extensible Prioritizations extension) (#312)
* Added definitions for RFC9220 (Extended Connect extension) (#325)
* Editorial and formatting changes (#298, #258, #299, #304, #327)

## Since draft-ietf-quic-qlog-h3-events-03:
{:numbered="false"}

* Ensured consistent use of RawInfo to indicate raw wire bytes (#243)
* Changed HTTPStreamTypeSet:raw_stream_type to stream_type_value (#54)
* Changed HTTPUnknownFrame:raw_frame_type to frame_type_value (#54)
* Renamed max_header_list_size to max_field_section_size (#282)

## Since draft-ietf-quic-qlog-h3-events-02:
{:numbered="false"}

* Renamed HTTPStreamType data to request (#222)
* Added HTTPStreamType value unknown (#227)
* Added HTTPUnknownFrame (#224)
* Replaced old and new fields with stream_type in HTTPStreamTypeSet (#240)
* Changed HTTPFrame to a CDDL plug type (#257)
* Moved data definitions out of the appendix into separate sections
* Added overview Table of Contents

## Since draft-ietf-quic-qlog-h3-events-01:
{:numbered="false"}

* No changes - new draft to prevent expiration

## Since draft-ietf-quic-qlog-h3-events-00:
{:numbered="false"}

* Change the data definition language from TypeScript to CDDL (#143)

## Since draft-marx-qlog-event-definitions-quic-h3-02:
{:numbered="false"}

* These changes were done in preparation of the adoption of the drafts by the QUIC
  working group (#137)
* Split QUIC and HTTP/3 events into two separate documents
* Moved RawInfo, Importance, Generic events and Simulation events to the main
  schema document.

## Since draft-marx-qlog-event-definitions-quic-h3-01:
{:numbered="false"}

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
{:numbered="false"}

* Event and category names are now all lowercase
* Added many new events and their definitions
* "type" fields have been made more specific (especially important for PacketType
  fields, which are now called packet_type instead of type)
* Events are given an importance indicator (issue \#22)
* Event names are more consistent and use past tense (issue \#21)
* Triggers have been redefined as properties of the "data" field and updated for most events (issue \#23)
