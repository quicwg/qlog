---
title: "qlog: Structured Logging for Network Protocols"
abbrev: qlog
docname: draft-ietf-quic-qlog-main-schema-latest
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

informative:
  QLOG-QUIC:
    I-D.ietf-quic-qlog-quic-events

  QLOG-H3:
    I-D.ietf-quic-qlog-h3-events

  ANRW-2020:
    target: https://qlog.edm.uhasselt.be/anrw/
    title: "Debugging QUIC and HTTP/3 with qlog and qvis"
    date: 2020-09
    author:
    -
      name: Robin Marx
    -
      name: Maxime Piraux
    -
      name: Peter Quax
    -
      name: Wim Lamotte


--- abstract

qlog provides extensible structured logging for network protocols, allowing for
easy sharing of data that benefits common debug and analysis methods and
tooling. This document describes key concepts of qlog: formats, files, traces,
events, and extension points. In this definition are the high-level log file
schemas, and main event schema. Requirements and guidelines for creating
protocol-specific event schema are also presented. All schema are independent of
serialization format, allowing logs to be represented in many ways such as JSON,
CSV, or protobuf.

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

Endpoint logging is a useful strategy for capturing and understanding how
applications using network protocols are behaving, particularly where protocols
have an encrypted wire image that restricts observers' ability to see what is
happening.

Many applications implement logging using a custom, non-standard logging format.
This has an effect on the tools and methods that are used to
analyze the logs, for example to perform root cause analysis of an
interoperability failure between distinct implementations. A lack of a common
format impedes the development of common tooling that can be used by all parties
that have access to logs.

qlog is an extensible structured logging for network protocols that allows for
easy sharing of data that benefits common debug and analysis methods and
tooling. This document describes key concepts of qlog: formats, files, traces,
events, and extension points. In this definition are the high-level log file
schemas, and main event schema. Requirements and guidelines for creating
protocol-specific event schema are also presented. Accompanying documents define event schema for QUIC ({{QLOG-QUIC}}) and HTTP/3 ({{QLOG-H3}}).

The goal of qlog is to provide amenities and default characteristics that each
logging file should contain (or should be able to contain), such that generic
and reusable toolsets can be created that can deal with logs from a variety of
different protocols and use cases.

As such, qlog provides versioning, metadata inclusion, log aggregation, event
grouping and log file size reduction techniques.

All qlog schema can be serialized in many ways (e.g., JSON, CBOR, protobuf,
etc). This document describes only how to employ {{!JSON=RFC8259}}, its subset
{{!I-JSON=RFC7493}}, and its streamable derivative
{{!JSON-Text-Sequences=RFC7464}}.


## Conventions and Terminology

{::boilerplate bcp14-tagged}

Serialization examples in this document use JSON ({{!JSON=RFC8259}}) unless
otherwise indicated.

## Use of CDDL

To define events and data structures, all qlog documents use the Concise Data
Definition Language {{!CDDL=RFC8610}}. This document uses the basic syntax, the
specific `text`, `uint`, `float32`, `float64`, `bool`, and `any` types, as well
as the `.default`, `.size`, and `.regexp` control operators, the `~` unwrapping
operator, and the `$` and `$$` extension points syntax from {{CDDL}}.

Additionally, this document defines the following custom types for
clarity:

~~~ cddl
; CDDL's uint is defined as being 64-bit in size
; but for many protocol fields it is better to be restrictive
; and explicit
uint8 = uint .size 1
uint16 = uint .size 2
uint32 = uint .size 4
uint64 = uint .size 8

; an even-length lowercase string of hexadecimally encoded bytes
; examples: 82dc, 027339, 4cdbfd9bf0
; this is needed because the default CDDL binary string (bytes/bstr)
; is only CBOR and not JSON compatible
hexstring = text .regexp "([0-9a-f]{2})*"
~~~
{: #cddl-custom-types-def title="Additional CDDL type definitions"}

All timestamps and time-related values (e.g., offsets) in qlog are
logged as `float64` in the millisecond resolution.

Other qlog documents can define their own CDDL-compatible (struct) types
(e.g., separately for each Packet type that a protocol supports).

The ordering of member fields in qlog CDDL type definitions is not significant.
The ordering of member fields in the serialization formats defined in this
document, JSON ({{format-json}}) and JSON Text Sequences ({{format-json-seq}}),
is not significant and qlog tools MUST NOT assume so. Other qlog serialization
formats MAY define field order significance, if they do they MUST define
requirements for qlog tools supporting those formats.

> Note to RFC editor: Please remove the following text in this section before
publication.

The main general CDDL syntax conventions in this document a reader
should be aware of for easy reading comprehension are:

* `? obj` : this object is optional
* `TypeName1 / TypeName2` : a union of these two types (object can be either type 1 OR
  type 2)
* `obj: TypeName` : this object has this concrete type
* `obj: [* TypeName]` : this object is an array of this type with
  minimum size of 0 elements
* `obj: [+ TypeName]` : this object is an array of this type with
  minimum size of 1 element
* `TypeName = ...` : defines a new type
* `EnumName = "entry1" / "entry2" / entry3 / ...`: defines an enum
* `StructName = { ... }` : defines a new struct type
* `;` : single-line comment
* `* text => any` : special syntax to indicate 0 or more fields that
  have a string key that maps to any value. Used to indicate a generic
  JSON object.

All timestamps and time-related values (e.g., offsets) in qlog are
logged as `float64` in the millisecond resolution.

Other qlog documents can define their own CDDL-compatible (struct) types
(e.g., separately for each Packet type that a protocol supports).

# Design Overview

The main tenets for the qlog design are:

* Streamable, event-based logging
* A flexible format that can reduce log producer overhead, at the cost of
  increased complexity for consumers (e.g. tools)
* Extensible and pragmatic
* Aggregation and transformation friendly (e.g., the top-level element
  for the non-streaming format is a container for individual traces,
  group_ids can be used to tag events to a particular context)
* Metadata is stored together with event data

This is achieved by a logical logging hierarchy of:

* Log file
  * Trace(s)
    * Event(s)

An abstract LogFile class is declared ({{abstract-logfile}}), from which all
concrete log file formats derive using log file schemas. This document defines
the QLogFile ({{qlog-file-schema}}) and QLogFileSeq ({{qlog-file-seq-schema}})
schemas.

A trace is conceptually fluid but the conventional use case is to group events
related to a single data flow, such as a single logical QUIC connection, at a
single vantage point ({{vantage-point}}). Concrete trace definitions relate to
the log file schemas they are contained in; see ({{traces}}, {{trace}}, and
{{traceseq}}).

Events are logged at a time instant and convey specific details of the logging
use case. For example, a QUIC packet being sent or received. This document
declares an abstract Event class ({{abstract-event}}) containing common fields, which
all concrete events derive from. Concrete events are defined by event schema
that declare a namespace, consisting of one or more categories, containing one
or more related event types. For example, this document defines the `main` event
schema structured as:

* `main` namespace
  * `generic` category
    * `error` event type
    * `warning` event type
    * `info` event type
    * `debug` event type
    * `verbose` event type
  * `simulation` category
    * `scenario` event type
    * `marker` event type

# Abstract LogFile Class {#abstract-logfile}

A Log file is intended to contain a collection of events that are in some way
related. An abstract LogFile class containing fields common to all log files is
defined. Each concrete log file format derives from this, extending it by
defining semantics and any custom fields.

~~~ cddl
LogFile = {
    file_schema: text
    serialization_format: text
    ? title: text
    ? description: text
    event_schemas: [+text]

    ; can contain any amount of custom fields
    * text => any
}
~~~
{: #abstract-logfile-def title="LogFile definition"}

The required "file_schema" field identifies the concrete log file format. It
MUST have a value that is an absolute URI; see {{schema-uri}} for rules and
guidance. In order to make it easier to parse and identify qlog files and their
serialization format, the "file_schema" and "serialization_format" fields
and their values SHOULD be in the first 256 characters/bytes of the resulting
log file.

The required "serialization_format" field indicates the serialization
format using a media type {{!RFC2046}}. It is case-insensitive.

The optional "title" and "description" fields provide additional free-text
information about the file.

The required "event_schema" field is described in {{event-types-and-schema}}.

## Concrete Schema URI {#schema-uri}

Concrete log file schemas MUST identify themselves using a URI.

Log schemas defined by RFCs SHOULD be URN of the form
`urn:ietf:params:qlog:file:<schema-identifier>`, where `<schema-identifier>` is
a globally-unique name. URN MUST be registered with IANA; see {{iana}}.

Private or non-standard event categories can use other URI formats. URIs that
contain a domain name SHOULD also contain a month-date in the form mmyyyy. For
example, "https://example.org/072024/customfileschema". The definition of the
file schema and assignment of the URI MUST have been authorized by the owner of
the domain name on or very close to that date. This avoids problems when domain
names change ownership. For example,

# QlogFile schema {#qlog-file-schema}

A qlog using the QlogFile schema can contain several individual traces and logs
from multiple vantage points that are in some way related. The top-level element
in this schema defines only a small set of "header" fields and an array of
component traces, defined in {{qlog-file-def}} as:

~~~ cddl
QlogFile = {
    ? traces: [+ Trace /
                 TraceError]
}
~~~
{: #qlog-file-def title="QlogFile definition"}

The QlogFile schema URI is `urn:ietf:params:qlog:file:contained`.

The optional "traces" field contains an array of qlog traces ({{trace}}), each
of which contain metadata and an array of qlog events ({{abstract-event}}).

The default serialization format is JSON; see {{format-json}} for guidance
on populating the "serialization_format" field and other considerations.
Where a qlog file is serialized to a JSON format, one of the downsides is that
it is inherently a non-streamable format. Put differently, it is not possible to
simply append new qlog events to a log file without "closing" this file at the
end by appending "]}]}". Without these closing tags, most JSON parsers will be
unable to parse the file entirely. The alternative QlogFileSeq
({{qlog-file-seq-schema}}) is better suited to streaming.

JSON serialization example:

~~~
{
    "file_schema": "urn:ietf:params:qlog:file:contained",
    "serialization_format": "application/qlog+json",
    "title": "Name of this particular qlog file (short)",
    "description": "Description for this group of traces (long)",
    "traces": [...]
}
~~~
{: #qlog-file-ex title="QlogFile example"}

## Traces

It can be advantageous to group several related qlog traces together in a single
file. For example, it is possible to simultaneously perform logging on the
client, on the server, and on a single point on their common network path. For
analysis, it is useful to aggregate these three individual traces together into
a single file, so it can be uniquely stored, transferred, and annotated.

The QlogFile "traces" field is an array that contains a list of individual qlog
traces. When capturing a qlog at a vantage point, it is expected that the traces
field contains a single entry. Files can be aggregated, for example as part of a
post-processing operation, by copying the traces in component to files into the
combined "traces" array of a new, aggregated qlog file.

## Trace {#trace}

The exact conceptual definition of a Trace can be fluid. For example, a trace
could contain all events for a single connection, for a single endpoint, for a
single measurement interval, for a single protocol, etc. In the normal use case
however, a trace is a log of a single data flow collected at a single location
or vantage point. For example, for QUIC, a single trace only contains events for
a single logical QUIC connection for either the client or the server.

A Trace contains some metadata in addition to qlog events, defined in
{{trace-def}} as:

~~~ cddl
Trace = {
    ? title: text
    ? description: text
    ? common_fields: CommonFields
    ? vantage_point: VantagePoint
    events: [* Event]
}
~~~
{: #trace-def title="Trace definition"}

The optional "title" and "description" fields provide additional free-text
information about the trace.

The optional "common_fields" field is described in {{common-fields}}.

The optional "vantage_point" field is described in {{vantage-point}}.

The semantics and context of the trace can mainly be deduced from the entries in
the "common_fields" list and "vantage_point" field.

JSON serialization example:

~~~~~~~~
{
    "title": "Name of this particular trace (short)",
    "description": "Description for this trace (long)",
    "common_fields": {
        "ODCID": "abcde1234",
        "time_format": "absolute"
    },
    "vantage_point": {
        "name": "backend-67",
        "type": "server"
    },
    "events": [...]
}
~~~~~~~~
{: #trace-ex title="Trace example"}

## TraceError

A TraceError indicates that an attempt to find/convert a file for inclusion in
the aggregated qlog was made, but there was an error during the process. Rather
than silently dropping the erroneous file, it can be explicitly included in the
qlog file as an entry in the "traces" array, defined in {{trace-error-def}} as:

~~~ cddl
TraceError = {
    error_description: text

    ; the original URI used for attempted find of the file
    ? uri: text
    ? vantage_point: VantagePoint
}
~~~
{: #trace-error-def title="TraceError definition"}

JSON serialization example:

~~~~~~~
{
    "error_description": "File could not be found",
    "uri": "/srv/traces/today/latest.qlog",
    "vantage_point": { type: "server" }
}
~~~~~~~
{: #trace-error-ex title="TraceError example"}

Note that another way to combine events of different traces in a single qlog file
is through the use of the "group_id" field, discussed in {{group-ids}}.

# QlogFileSeq schema {#qlog-file-seq-schema}

A qlog file using the QlogFileSeq schema can be serialized to a streamable JSON
format called JSON Text Sequences (JSON-SEQ) ({{!RFC7464}}). The top-level
element in this schema defines only a small set of "header" fields and an array
of component traces, defined in {{qlog-file-def}} as:

~~~ cddl
QlogFileSeq = {
    trace: TraceSeq
}
~~~
{: #qlog-file-seq-def title="QlogFileSeq definition"}

The QlogFileSeq schema URI is `urn:ietf:params:qlog:file:sequential`.

The required "trace" field contains a singular trace metadata. All qlog events
in the file are related to this trace; see {{traceseq}}.

See {{format-json-seq}} for guidance on populating the
"serialization_format" field and other serialization considerations.

JSON-SEQ serialization example:

~~~~~~~~
// list of qlog events, serialized in accordance with RFC 7464,
// starting with a Record Separator character and ending with a
// newline.
// For display purposes, Record Separators are rendered as <RS>

<RS>{
    "file_schema": "urn:ietf:params:qlog:file:sequential",
    "serialization_format": "application/qlog+json-seq",
    "title": "Name of JSON Text Sequence qlog file (short)",
    "description": "Description for this trace file (long)",
    "trace": {
      "common_fields": {
        "protocol_type": ["QUIC","HTTP3"],
        "group_id":"127ecc830d98f9d54a42c4f0842aa87e181a",
        "time_format":"relative",
        "reference_time": 1553986553572
      },
      "vantage_point": {
        "name":"backend-67",
        "type":"server"
      }
    }
}
<RS>{"time": 2, "name": "quic:parameters_set", "data": { ... } }
<RS>{"time": 7, "name": "quic:packet_sent", "data": { ... } }
...
~~~~~~~~
{: #json-seq-ex title="Top-level element"}

## TraceSeq

TraceSeq is used with QlogFileSeq. It is conceptually similar to a Trace, with
the exception that qlog events are not contained within it, but rather appended
after it in a QlogFileSeq.

~~~ cddl
TraceSeq = {
    ? title: text
    ? description: text
    ? common_fields: CommonFields
    ? vantage_point: VantagePoint
}
~~~
{: #trace-seq-def title="TraceSeq definition"}

# VantagePoint {#vantage-point}

A VantagePoint describes the vantage point from which a trace originates,
defined in {{vantage-point-def}} as:

~~~ cddl
VantagePoint = {
    ? name: text
    type: VantagePointType
    ? flow: VantagePointType
}

; client = endpoint which initiates the connection
; server = endpoint which accepts the connection
; network = observer in between client and server
VantagePointType = "client" /
                   "server" /
                   "network" /
                   "unknown"
~~~
{: #vantage-point-def title="VantagePoint definition"}

JSON serialization examples:

~~~~~~~~
{
    "name": "aioquic client",
    "type": "client"
}

{
    "name": "wireshark trace",
    "type": "network",
    "flow": "client"
}
~~~~~~~~
{: #vantage-point-ex title="VantagePoint example"}

The flow field is only required if the type is "network" (for example, the trace
is generated from a packet capture). It is used to disambiguate events like
"packet sent" and "packet received". This is indicated explicitly because for
multiple reasons (e.g., privacy) data from which the flow direction can be
otherwise inferred (e.g., IP addresses) might not be present in the logs.

Meaning of the different values for the flow field:
  * "client" indicates that this vantage point follows client data flow semantics (a
    "packet sent" event goes in the direction of the server).
  * "server" indicates that this vantage point follow server data flow semantics (a
    "packet sent" event goes in the direction of the client).
  * "unknown" indicates that the flow's direction is unknown.

Depending on the context, tools confronted with "unknown" values in the
vantage_point can either try to heuristically infer the semantics from
protocol-level domain knowledge (e.g., in QUIC, the client always sends the first
packet) or give the user the option to switch between client and server
perspectives manually.

# Abstract Event Class {#abstract-event}

Events are logged at a time instant and convey specific details of the logging
use case. An abstract Event class containing fields common to all events is
defined.

~~~ cddl
Event = {
    time: float64
    name: text
    data: $ProtocolEventData
    ? path: PathID
    ? time_format: TimeFormat
    ? protocol_type: ProtocolTypeList
    ? group_id: GroupID
    ? system_info: SystemInformation

    ; events can contain any amount of custom fields
    * text => any
}
~~~
{: #event-def title="Event definition"}

Each qlog event MUST contain the mandatory fields: "time"
({{time-based-fields}}), "name" ({{event-types-and-schema}}), and "data" ({{data-field}}).

Each qlog event, is an instance of a concrete event type that derives from the
abstract Event class; see {{event-types-and-schema}}. They extend it by defining
the specific values and semantics of common fields, in particular the `name` and
`data` fields. Furthermore, they can optionally add custom fields.

Each qlog event MAY contain the optional fields: "time_format"
({{time-based-fields}}), "protocol_type" ({{protocol-type-field}}), "trigger"
({{trigger-field}}), and "group_id" ({{group-ids}}).

Multiple events can appear in a Trace or TraceSeq and they might contain fields
with identical values. It is possible to optimize out this duplication using
"common_fields" ({{common-fields}}).

Example qlog event:

~~~~~~~~
{
    "time": 1553986553572,

    "name": "quic:packet_sent",
    "data": { ... },

    "protocol_type":  ["QUIC","HTTP3"],
    "group_id": "127ecc830d98f9d54a42c4f0842aa87e181a",

    "time_format": "absolute",

    "ODCID": "127ecc830d98f9d54a42c4f0842aa87e181a"
}
~~~~~~~~
{: #event-ex title="Event example"}

## Timestamps {#time-based-fields}

An event's "time" field indicates the timestamp at which the event occurred. Its value is
typically the Unix timestamp since the 1970 epoch (number of milliseconds since
midnight UTC, January 1, 1970, ignoring leap seconds). However, qlog supports two
more succinct timestamps formats to allow reducing file size. The employed format
is indicated in the "time_format" field, which allows one of three values:
"absolute", "delta" or "relative".

~~~ cddl
TimeFormat = "absolute" /
             "delta" /
             "relative"
~~~
{: #time-format-def title="TimeFormat definition"}

* Absolute: Include the full absolute timestamp with each event. This approach
  uses the largest amount of characters. This is also the default value of the
  "time_format" field.
* Delta: Delta-encode each time value on the previously logged value. The first
  event in a trace typically logs the full absolute timestamp. This approach uses
  the least amount of characters.
* Relative: Specify a full "reference_time" timestamp (typically this is done
  up-front in "common_fields", see {{common-fields}}) and include only
  relatively-encoded values based on this reference_time with each event. The
  "reference_time" value is typically the first absolute timestamp. This approach
  uses a medium amount of characters.

The first option is good for stateless loggers, the second and third for stateful
loggers. The third option is generally preferred, since it produces smaller files
while being easier to reason about. An example for each option can be seen in
{{time-format-ex}}.

~~~~~~~~
The absolute approach will use:
1500, 1505, 1522, 1588

The delta approach will use:
1500, 5, 17, 66

The relative approach will:
- set the reference_time to 1500 in "common_fields"
- use: 0, 5, 22, 88
~~~~~~~~
{: #time-format-ex title="Three different approaches for logging timestamps"}

One of these options is typically chosen for the entire trace (put differently:
each event has the same value for the "time_format" field). Each event MUST
include a timestamp in the "time" field.

Events in each individual trace SHOULD be logged in strictly ascending timestamp
order (though not necessarily absolute value, for the "delta" format). Tools MAY
sort all events on the timestamp before processing them, though are not required
to (as this could impose a significant processing overhead). This can be a problem
especially for multi-threaded and/or streaming loggers, who could consider using a
separate post-processor to order qlog events in time if a tool do not provide this
feature.

Timestamps do not have to use the UNIX epoch timestamp as their reference. For
example for privacy considerations, any initial reference timestamps (for example
"endpoint uptime in ms" or "time since connection start in ms") can be chosen.
Tools SHOULD NOT assume the ability to derive the absolute Unix timestamp from
qlog traces, nor allow on them to relatively order events across two or more
separate traces (in this case, clock drift should also be taken into account).


## Path {#path-field}

A qlog event can be associated with a single "network path" (usually, but not
always, identified by a 4-tuple of IP addresses and ports). In many cases, the
path will be the same for all events in a given trace, and does not need to be
logged explicitly with each event. In this case, the "path" field can be omitted
(in which case the default value of "" is assumed) or reflected in
"common_fields" instead (see {{common-fields}}).

However, in some situations, such as during QUIC's Connection Migration or when
using Multipath features, it is useful to be able to split events across
multiple (concurrent) paths.

Definition:

~~~ cddl
PathID = text .default ""
~~~
{: #path-def title="PathID definition"}


The "path" field is an identifier that is associated with a single network path.
This document intentionally does not define further how to choose this
identifier's value per-path or how to potentially log other parameters that can
be associated with such a path. This is left for other documents. Implementers
are free to encode path information directly into the PathID or to log
associated info in a separate event. For example, QUIC has the "path_assigned"
event to couple the PathID value to a specific path configuration, see
{{QLOG-QUIC}}.

## ProtocolTypeList and ProtocolType {#protocol-type-field}

An event's "protocol_type" array field indicates to which protocols (or protocol
"stacks") this event belongs. This allows a single qlog file to aggregate traces
of different protocols (e.g., a web server offering both TCP+HTTP/2 and
QUIC+HTTP/3 connections).

~~~ cddl
ProtocolTypeList = [+ $ProtocolType]

$ProtocolType /= "UNKNOWN"
~~~
{: #protocol-type-def title="ProtocolTypeList and ProtocolType socket definition"}

For example, QUIC and HTTP/3 events have the "QUIC" and "HTTP3" protocol_type
entry values, see {{QLOG-QUIC}} and {{QLOG-H3}}.

Typically however, all events in a single trace are of the same few protocols, and
this array field is logged once in "common_fields", see {{common-fields}}.

## Triggers {#trigger-field}

Sometimes, additional information is needed in the case where a single event can
be caused by a variety of other events. In the normal case, the context of the
surrounding log messages gives a hint as to which of these other events was the
cause. However, in highly-parallel and optimized implementations, corresponding
log messages might separated in time. Another option is to explicitly indicate
these "triggers" in a high-level way per-event to get more fine-grained
information without much additional overhead.

In qlog, the optional "trigger" field contains a string value describing
the reason (if any) for this event instance occurring, see
{{data-field}}. While this "trigger" field could be a property of the
qlog Event itself, it is instead a property of the "data" field instead.
This choice was made because many event types do not include a trigger
value, and having the field at the Event-level would cause overhead in
some serializations. Additional information on the trigger can be added
in the form of additional member fields of the "data" field value, yet
this is highly implementation-specific, as are the trigger field's
string values.

One purely illustrative example of some potential triggers for QUIC's
"packet_dropped" event is shown in {{trigger-ex}}:

~~~~~~~~
TransportPacketDropped = {
    ? packet_type: PacketType
    ? raw_length: uint16
    ? trigger: "key_unavailable" /
               "unknown_connection_id" /
               "decrypt_error" /
               "unsupported_version"
}
~~~~~~~~
{: #trigger-ex title="Trigger example"}

## Grouping {#group-ids}

As discussed in {{trace}}, a single qlog file can contain several traces taken
from different vantage points. However, a single trace from one endpoint can also
contain events from a variety of sources. For example, a server implementation
might choose to log events for all incoming connections in a single large
(streamed) qlog file. As such, a method for splitting up events belonging
to separate logical entities is required.

The simplest way to perform this splitting is by associating a "group id"
to each event that indicates to which conceptual "group" each event belongs. A
post-processing step can then extract events per group. However, this group
identifier can be highly protocol and context-specific. In the example above,
the QUIC "Original Destination Connection ID" could be used to uniquely identify a
connection. As such, they might add a "ODCID" field to each event. However, a
middlebox logging IP or TCP traffic might rather use four-tuples to identify
connections, and add a "four_tuple" field.

As such, to provide consistency and ease of tooling in cross-protocol and
cross-context setups, qlog instead defines the common "group_id" field, which
contains a string value. Implementations are free to use their preferred string
serialization for this field, so long as it contains a unique value per logical
group. Some examples can be seen in {{group-id-ex}}.

~~~ cddl
GroupID = text
~~~
{: #group-id-def title="GroupID definition"}

JSON serialization example for events grouped by four tuples
and QUIC connection IDs:

~~~~~~~~
"events": [
    {
        "time": 1553986553579,
        "protocol_type": ["TCP", "TLS", "HTTP2"],
        "group_id": "ip1=2001:67c:1232:144:9498:6df6:f450:110b,
                   ip2=2001:67c:2b0:1c1::198,port1=59105,port2=80",
        "name": "quic:packet_received",
        "data": { ... }
    },
    {
        "time": 1553986553581,
        "protocol_type": ["QUIC","HTTP3"],
        "group_id": "127ecc830d98f9d54a42c4f0842aa87e181a",
        "name": "quic:packet_sent",
        "data": { ... }
    }
]
~~~~~~~~
{: #group-id-ex title="GroupID example"}

Note that in some contexts (for example a Multipath transport protocol) it might
make sense to add additional contextual per-event fields (for example "path_id"),
rather than use the group_id field for that purpose.

Note also that, typically, a single trace only contains events belonging to a
single logical group (for example, an individual QUIC connection). As such,
instead of logging the "group_id" field with an identical value for each event
instance, this field is typically logged once in "common_fields", see
{{common-fields}}.

## SystemInformation

The "system_info" field can be used to record system-specific details related to an
event. This is useful, for instance, where an application splits work across
CPUs, processes, or threads and events for a single trace occur on potentially
different combinations thereof. Each field is optional to support deployment
diversity.

~~~ cddl
SystemInformation = {
  ? processor_id: uint32
  ? process_id: uint32
  ? thread_id: uint32
}
~~~

## CommonFields {#common-fields}

As discussed in the previous sections, information for a typical qlog event varies
in three main fields: "time", "name" and associated data. Additionally, there are
also several more advanced fields that allow mixing events from different
protocols and contexts inside of the same trace (for example "protocol_type" and
"group_id"). In most "normal" use cases however, the values of these advanced
fields are consistent for each event instance (for example, a single trace
contains events for a single QUIC connection).

To reduce file size and making logging easier, qlog uses the "common_fields" list
to indicate those fields and their values that are shared by all events in this
component trace. This prevents these fields from being logged for each individual
event. An example of this is shown in {{common-fields-ex}}.

~~~~~~~~
JSON serialization with repeated field values
per-event instance:

{
    "events": [{
            "group_id": "127ecc830d98f9d54a42c4f0842aa87e181a",
            "protocol_type": ["QUIC","HTTP3"],
            "time_format": "relative",
            "reference_time": 1553986553572,

            "time": 2,
            "name": "quic:packet_received",
            "data": { ... }
        },{
            "group_id": "127ecc830d98f9d54a42c4f0842aa87e181a",
            "protocol_type": ["QUIC","HTTP3"],
            "time_format": "relative",
            "reference_time": 1553986553572,

            "time": 7,
            "name": "http:frame_parsed",
            "data": { ... }
        }
    ]
}

JSON serialization with repeated field values instead
extracted to common_fields:

{
    "common_fields": {
        "group_id": "127ecc830d98f9d54a42c4f0842aa87e181a",
        "protocol_type": ["QUIC","HTTP3"],
        "time_format": "relative",
        "reference_time": 1553986553572
    },
    "events": [
        {
            "time": 2,
            "name": "quic:packet_received",
            "data": { ... }
        },{
            "time": 7,
            "name": "http:frame_parsed",
            "data": { ... }
        }
    ]
}
~~~~~~~~
{: #common-fields-ex title="CommonFields example"}

An event's "common_fields" field is a generic dictionary of key-value pairs, where the
key is always a string and the value can be of any type, but is typically also a
string or number. As such, unknown entries in this dictionary MUST be disregarded
by the user and tools (i.e., the presence of an unknown field is explicitly NOT an
error).

The list of default qlog fields that are typically logged in common_fields (as
opposed to as individual fields per event instance) are shown in the listing
below:

~~~ cddl
CommonFields = {
    ? path: PathID
    ? time_format: TimeFormat
    ? reference_time: float64
    ? protocol_type: ProtocolTypeList
    ? group_id: GroupID
    * text => any
}
~~~
{: #common-fields-def title="CommonFields definition"}

Tools MUST be able to deal with these fields being defined either on each event
individually or combined in common_fields. Note that if at least one event in a
trace has a different value for a given field, this field MUST NOT be added to
common_fields but instead defined on each event individually. Good example of such
fields are "time" and "data", who are divergent by nature.

# Concrete Event Types and Event Schema {#event-types-and-schema}

Concrete event types are defined in event schema, which declare a namespace
consisting of one or more categories, each containing related event types. This
document defines the `main` event schema. Other examples are the `quic`
{{QLOG-QUIC}} and `h3` {{QLOG-H3}} event schema.

Concrete events MAY extend any part of the abstract Event class, including extending the "data" field ({{data-field}}) of adding custom fields.

Event schema MUST define a registered non-empty namespace of type `text`.

Event categories MUST belong to a single event schema. The MUST have a
registered non-empty globally-unique identifier of type `text` and MUST have a
single dereferencable URI. That URI MUST be absolute and MUST indicate the
category identifier using a fragment identifier (characters after a "#" in the
URI). For event categories in schema defined by RFCs, the URI SHOULD be a URN of
the form `urn:ietf:params:qlog:<schema namespace>#<category identifier>`.
Private or non-standard event categories can use other URI formats. URIs that
contain a domain name SHOULD also contain a month-date in the form mmyyyy. The
definition of the category and assignment of the URI MUST have been authorized by
the owner of the domain name on or very close to that date. (This avoids
problems when domain names change ownership.)

The registration requirements for extension schema URIs are detailed in
{{iana}}.

Concrete event types MUST belong to a single event category and MUST have a
non-empty identifier of type `text`.

The value of a qlog event `name` field MUST be the concatenation of category
identifier, colon (':'), and event type identifier. By virtue of the identifier
requirements, names are globally-unique. Thus, log files can contain events from
multiple schemas without the risk of name collisions.

In the following hypothetical example, a qlog file contains events belonging to
multiple standard and non-standard categories belonging to different schema
namespaces rick, john, and pickle. The standard categories use a URN format, the
non-standard categories use a URI with domain name.

~~~
"event_categories": [
                      "urn:ietf:params:qlog:rick#roll",
                      "urn:ietf:params:qlog:rick#astley",
                      "urn:ietf:params:qlog:rick#moranis",
                      "urn:ietf:params:qlog:john#doe",
                      "urn:ietf:params:qlog:john#candy",
                      "urn:ietf:params:qlog:john#goodman",
                      "https://example.com/032024/pickle.html#pepper",
                      "https://example.com/032024/pickle.html#lilly",
                      "https://example.com/032024/pickle.html#rick",
                    ]
~~~
{: #event-categories title="Example event_categories serialization"}

## Extending the Data Field {#data-field}

An event's "data" field is a generic key-value map (e.g., JSON object). It
defines the per-event metadata that is to be logged. Its specific subfields and
their semantics are defined per concrete event type. For example, data field
definitions for QUIC and HTTP/3 can be found in {{QLOG-QUIC}} and {{QLOG-H3}}.

In order to keep qlog fully extensible, two separate CDDL extension points
("sockets" or "plugs") are used to fully define data fields.

Firstly, to allow existing data field definitions to be extended (for example by
adding an additional field needed for a new protocol feature), a CDDL "group
socket" is used. This takes the form of a subfield with a name of
`* $$CATEGORY-NAME-extension`. This field acts as a placeholder that can later be
replaced with newly defined fields by assigning them to the socket with the
`//=` operator. Multiple extensions can be assigned to the same group socket. An
example is shown in {{groupsocket-extension-example}}.

~~~~~~~~
; original definition in document A
MyCategoryEventX = {
    field_a: uint8

    * $$mycategory-eventx-extension
}

; later extension of EventX in document B
$$mycategory-eventx-extension //= (
  ? additional_field_b: bool
)

; another extension of EventX in document C
$$mycategory-eventx-extension //= (
  ? additional_field_c: text
)

; if document A, B and C are then used in conjunction,
; the combined MyCategoryEventX CDDL is equivalent to this:
MyCategoryEventX = {
    field_a: uint8

    ? additional_field_b: bool
    ? additional_field_c: text
}
~~~~~~~~
{: #groupsocket-extension-example title="Example of using a generic CDDL group socket to extend an existing event data definition"}

Secondly, to allow documents to define fully new event data field definitions
(as opposed to extend existing ones), a CDDL "type socket" is used. For this
purpose, the type of the "data" field in the qlog Event type (see {{event-def}})
is the extensible `$ProtocolEventData` type. This field acts as an open enum of
possible types that are allowed for the data field. As such, any new event data
field is defined as its own CDDL type and later merged with the existing
`$ProtocolEventData` enum using the `/=` extension operator. Any generic
key-value map type can be assigned to `$ProtocolEventData` (the only common
"data" subfield defined in this document is the optional `trigger` field, see
{{trigger-field}}). An example of this setup is shown in
{{protocoleventdata-def}}.

~~~~~~~~
; We define two separate events in a single document
MyCategoryEvent1 /= {
    field_1: uint8

    ? trigger: text

    * $$mycategory-event1-extension
}

MyCategoryEvent2 /= {
    field_2: bool

    ? trigger: text

    * $$mycategory-event2-extension
}

; the events are both merged with the existing
; $ProtocolEventData type enum
$ProtocolEventData /= MyCategoryEvent1 / MyCategoryEvent2

; the "data" field of a qlog event can now also be of type
; MyCategoryEvent1 and MyCategoryEvent2
~~~~~~~~
{: #protocoleventdata-def title="ProtocolEventData extension"}

Documents defining new qlog events MUST properly extend `$ProtocolEventData`
when defining data fields to enable automated validation of aggregated qlog
schemas. Furthermore, they SHOULD properly add a `* $$CATEGORY-NAME-extension`
extension field to newly defined event data to allow the new events to be
properly extended by other documents.

A combined but purely illustrative example of the use of both extension points
for a conceptual QUIC "packet_sent" event is shown in {{data-ex}}:

~~~~~~~~
; defined in the main QUIC event document
TransportPacketSent = {
    ? packet_size: uint16
    header: PacketHeader
    ? frames:[* QuicFrame]
    ? trigger: "pto_probe" /
               "retransmit_timeout" /
               "bandwidth_probe"

    * $$transport-packetsent-extension
}

; Add the event to the global list of recognized qlog events
$ProtocolEventData /= TransportPacketSent

; Defined in a separate document that describes a
; theoretical QUIC protocol extension
$$transport-packetsent-extension //= (
  ? additional_field: bool
)

; If both documents are utilized at the same time,
; the following JSON serialization would pass an automated
; CDDL schema validation check:

{
  "time": 123456,
  "category": "transport",
  "name": "packet_sent",
  "data": {
      "packet_size": 1280,
      "header": {
          "packet_type": "1RTT",
          "packet_number": 123
      },
      "frames": [
          {
              "frame_type": "stream",
              "length": 1000,
              "offset": 456
          },
          {
              "frame_type": "padding"
          }
      ],
      additional_field: true
  }
}
~~~~~~~~
{: #data-ex title="Example of an extended 'data' field for a conceptual QUIC packet_sent event"}

## Event Importance Levels {#importance}

Depending on how events are designed, it may be that several events allow the
logging of similar or overlapping data. For example the separate QUIC
`connection_started` event overlaps with the more generic
`connection_state_updated`. In these cases, it is not always clear which event
should be logged or used, and which event should take precedence if e.g., both are
present and provide conflicting information.

To aid in this decision making, qlog defines three event importance levels, in
decreasing order of importance and expected usage:

* Core
* Base
* Extra

Concrete event types SHOULD define an importance level.

Core-level events SHOULD be present in all qlog files for a
given protocol. These are typically tied to basic packet and frame parsing and
creation, as well as listing basic internal metrics. Tool implementers SHOULD
expect and add support for these events, though SHOULD NOT expect all Core events
to be present in each qlog trace.

Base-level events add additional debugging options and MAY be present in qlog
files. Most of these can be implicitly inferred from data in Core events (if
those contain all their properties), but for many it is better to log the events
explicitly as well, making it clearer how the implementation behaves. These
events are for example tied to passing data around in buffers, to how internal
state machines change, and used to help show when decisions are actually made
based on received data. Tool implementers SHOULD at least add support for
showing the contents of these events, if they do not handle them explicitly.

Extra-level events are considered mostly useful for low-level debugging of the
implementation, rather than the protocol. They allow more fine-grained tracking
of internal behavior. As such, they MAY be present in qlog files and tool
implementers MAY add support for these, but they are not required to.

Note that in some cases, implementers might not want to log for example data
content details in Core-level events due to performance or privacy considerations.
In this case, they SHOULD use (a subset of) relevant Base-level events instead to
ensure usability of the qlog output. As an example, implementations that do not
log QUIC `packet_received` events and thus also not which (if any) ACK frames the
packet contains, SHOULD log `packets_acked` events instead.

Finally, for event types whose data (partially) overlap with other event types'
definitions, where necessary the event definition document should include explicit
guidance on which to use in specific situations.

## Tooling Expectations

qlog is an extensible format and it is expected that new event schema will
emerge that define new categories, event types,(e.g., a per-event field
indicating its privacy properties or
path_id in multipath protocols), as well as values for the "trigger" property
within the "data" field, or other member fields of the "data" field, as they see
fit.

It SHOULD NOT be expected that general-purpose tools will recognize or visualize
all forms of qlog extension. Tools SHOULD allow for the presence of unknown
event fields and make an effort to visualize even unknown data if possible, otherwise they MUST ignore it.

## Further Design Guidance

There are several ways of defining concrete event types. In practice, two main types of
approach have been observed: a) those that map directly to concepts seen in the
protocols (e.g., `packet_sent`) and b) those that act as aggregating events that
combine data from several possible protocol behaviors or code paths into one
(e.g., `parameters_set`). The latter are typically used as a means to reduce the
amount of unique event definitions, as reflecting each possible protocol event
as a separate qlog entity would cause an explosion of event types.

Additionally, logging duplicate data is typically prevented as much as possible.
For example, packet header values that remain consistent across many packets are
split into separate events (for example `spin_bit_updated` or
`connection_id_updated` for QUIC).

Finally, when logging additional state change events, those state changes can
often be directly inferred from data on the wire (for example flow control limit
changes). As such, if the implementation is bug-free and spec-compliant, logging
additional events is typically avoided. Exceptions have been made for common
events that benefit from being easily identifiable or individually logged (for
example `packets_acked`).

# Main Event Schema

The main event schema defines categories and event types that are common across
protocols, applications, and use cases. The schema namespace is "main".

## Generic Events

In typical logging setups, users utilize a discrete number of well-defined logging
categories, levels or severities to log freeform (string) data. This generic
events category replicates this approach to allow implementations to fully replace
their existing text-based logging by qlog. This is done by providing events to log
generic strings for the typical well-known logging levels (error, warning, info,
debug, verbose). The category identifier is "generic".

~~~ cddl
GenericEventData = GenericError /
                GenericWarning /
                GenericInfo /
                GenericDebug

$ProtocolEventData /= GenericEventData
~~~
{: #generic-events-def title="GenericEventData and ProtocolEventData extension"}

The event types are further defined below, their identifier is the heading name.

### error

Used to log details of an internal error that might not get reflected on the
wire. The event indentifier is `error has Core importance level.

~~~ cddl
GenericError = {
    ? code: uint64
    ? message: text

    * $$generic-error-extension
}
~~~
{: #generic-error-def title="GenericError definition"}

### warning

Used to log details of an internal warning that might not get reflected on the
wire. It has Base importance level; see {{importance}}.

~~~ cddl
GenericWarning = {
    ? code: uint64
    ? message: text

    * $$generic-warning-extension
}
~~~
{: #generic-warning-def title="GenericWarning definition"}

### info

Used mainly for implementations that want to use qlog as their one and only
logging format but still want to support unstructured string messages. The event
has Extra importance level; see {{importance}}.

~~~ cddl
GenericInfo = {
    message: text

    * $$generic-info-extension
}
~~~
{: #generic-info-def title="GenericInfo definition"}

### debug

Used mainly for implementations that want to use qlog as their one and only
logging format but still want to support unstructured string messages. The event
has Extra importance level; see {{importance}}.

~~~ cddl
GenericDebug = {
    message: text

    * $$generic-debug-extension
}
~~~
{: #generic-debug-def title="GenericDebug definition"}

### verbose

Used mainly for implementations that want to use qlog as their one and only
logging format but still want to support unstructured string messages. The event
has Extra importance level; see {{importance}}.

~~~ cddl
GenericVerbose = {
    message: text

    * $$generic-verbose-extension
}
~~~
{: #generic-verbose-def title="GenericVerbose definition"}

## Simulation Events

When evaluating a protocol implementation, one typically sets up a series of
interoperability or benchmarking tests, in which the test situations can change
over time. For example, the network bandwidth or latency can vary during the test,
or the network can be fully disable for a short time. In these setups, it is
useful to know when exactly these conditions are triggered, to allow for proper
correlation with other events. The category identifier is "simulation".

~~~ cddl
SimulationEventData = SimulationScenario /
                SimulationMarker

$ProtocolEventData /= SimulationEventData
~~~
{: #sim-events-def title="SimulationEventData and ProtocolEventData extension"}

The event types are further defined below, their identifier is the heading name.

### scenario

Used to specify which specific scenario is being tested at this particular
instance. This supports, for example, aggregation of several simulations into
one trace (e.g., split by `group_id`). It has Extra importance level; see
{{importance}}.

~~~ cddl
SimulationScenario = {
    ? name: text
    ? details: {* text => any }

    * $$simulation-scenario-extension
}
~~~
{: #simulation-scenario-def title="SimulationScenario definition"}

### marker

Used to indicate when specific emulation conditions are triggered at set times
(e.g., at 3 seconds in 2% packet loss is introduced, at 10s a NAT rebind is
triggered). It has Extra importance level; see {{importance}}.

~~~ cddl
SimulationMarker = {
    ? type: text
    ? message: text

    * $$simulation-marker-extension
}
~~~
{: #simulation-marker-def title="SimulationMarker definition"}


# Raw packet and frame information {#raw-info}

While qlog is a high-level logging format, it also allows the inclusion of most
raw wire image information, such as byte lengths and byte values. This is useful
when for example investigating or tuning packetization behavior or determining
encoding/framing overheads. However, these fields are not always necessary, can
take up considerable space, and can have a considerable privacy and security
impact (see {{privacy}}). Where applicable, these fields are grouped in a
separate, optional, field named "raw" of type RawInfo. The exact definition of
entities, headers, trailers and payloads depend on the protocol used.

~~~ cddl
RawInfo = {

    ; the full byte length of the entity (e.g., packet or frame),
    ; including possible headers and trailers
    ? length: uint64

    ; the byte length of the entity's payload,
    ; excluding possible headers or trailers
    ? payload_length: uint64

    ; the (potentially truncated) contents of the full entity,
    ; including headers and possibly trailers
    ? data: hexstring
}
~~~
{: #raw-info-def title="RawInfo definition"}

The RawInfo:data field can be truncated for privacy or security purposes, see
{{truncated-values}}. In this case, the length and payload_length fields should
still indicate the non-truncated lengths when used for debugging purposes.

This document does not specify explicit header_length or trailer_length fields.
In protocols without trailers, header_length can be calculated by subtracting
the payload_length from the length. In protocols with trailers (e.g., QUIC's
AEAD tag), event definition documents SHOULD define how to support header_length
calculation.

# Serializing qlog {#concrete-formats}

qlog schema definitions in this document are intentionally agnostic to
serialization formats. The choice of format is an implementation decision.

Other documents related to qlog (for example event definitions for specific
protocols), SHOULD be similarly agnostic to the employed serialization format
and SHOULD clearly indicate this. If not, they MUST include an explanation on
which serialization formats are supported and on how to employ them correctly.

Serialization formats make certain tradeoffs between usability, flexibility,
interoperability, and efficiency. Implementations should take these into
consideration when choosing a format. Some examples of possible formats are
JSON, CBOR, CSV, protocol buffers, flatbuffers, etc. which each have their own
characteristics. For instance, a textual format like JSON can be more flexible
than a binary format but more verbose, typically making it less efficient than a
binary format. A plaintext readable (yet relatively large) format like JSON is
potentially more usable for users operating on the logs directly, while a more
optimized yet restricted format can better suit the constraints of a large scale
operation. A custom or restricted format could be more efficient for analysis
with custom tooling but might not be interoperable with general-purpose qlog
tools.

Considering these tradeoffs, JSON-based serialization formats provide features
that make them a good starting point for qlog flexibility and interoperability.
For these reasons, JSON is a recommended default and expanded considerations are
given to how to map qlog to JSON ({{format-json}}, and its streaming counterpart
JSON Text Sequences ({{format-json-seq}}. {{json-interop}} presents
interoperability considerations for both formats, and {{optimizations}} presents
potential optimizations.

Serialization formats require appropriate deserializers/parsers. The
"serialization_format" field ({{abstract-logfile}}) is used to indicate the chosen
serialization format.

## qlog to JSON mapping {#format-json}

As described in {{qlog-file-schema}}, JSON is the default qlog serialization.
When mapping qlog to normal JSON, QlogFile ({{qlog-file-def}}) is used. The
Media Type is "application/qlog+json" per {{!RFC6839}}. The file
extension/suffix SHOULD be ".qlog".

In accordance with {{Section 8.1 of !RFC8259}}, JSON files are required to use
UTF-8 both for the file itself and the string values it contains. In addition,
all qlog field names MUST be lowercase when serialized to JSON.

In order to serialize CDDL-based qlog event and data structure
definitions to JSON, the official CDDL-to-JSON mapping defined in
{{Appendix E of CDDL}} SHOULD be employed.

## qlog to JSON Text Sequences mapping {#format-json-seq}

One of the downsides of using normal JSON is that it is inherently a
non-streamable format. A qlog serializer could work around this by opening a
file, writing the required opening data, streaming qlog events by appending
them, and then finalizing the log by appending appropriate closing tags e.g.,
"]}]}". However, failure to append closing tags, could lead to problems because
most JSON parsers will fail if a document is malformed. Some streaming JSON
parsers are able to handle missing closing tags, however they are not widely
deployed in popular environments (e.g., Web browsers)

To overcome the issues related to JSON streaming, a qlog mapping to a streamable
JSON format called JSON Text Sequences (JSON-SEQ) ({{!RFC7464}}) is provided.

JSON Text Sequences are very similar to JSON, except that objects are
serialized as individual records, each prefixed by an ASCII Record Separator
(\<RS\>, 0x1E), and each ending with an ASCII Line Feed character (\n, 0x0A). Note
that each record can also contain any amount of newlines in its body, as long as
it ends with a newline character before the next \<RS\> character.

In order to leverage the streaming capability, each qlog event is serialized and
interpreted as an individual JSON Text Sequence record, that is appended as a
new object to the back of an event stream or log file. Put differently, unlike
default JSON, it does not require a document to be wrapped as a full object with
"{ ... }" or "\[... \]".

This alternative record streaming approach cannot be accommodated by QlogFile
({{qlog-file-def}}). Instead, QlogFileSeq is defined in {{qlog-file-seq-def}},
which notably includes only a single trace (TraceSeq) and omits an explicit
"events" array. An example is provided in {{json-seq-ex}}. The "group_id" field
can still be used on a per-event basis to include events from conceptually
different sources in a single JSON-SEQ qlog file.

When mapping qlog to JSON-SEQ, the Media Type is "application/qlog+json-seq" per
{{!RFC8091}}. The file extension/suffix SHOULD be ".sqlog" (for "streaming"
qlog).

While not specifically required by the JSON-SEQ specification, all qlog field
names MUST be lowercase when serialized to JSON-SEQ.

In order to serialize all other CDDL-based qlog event and data structure
definitions to JSON-SEQ, the official CDDL-to-JSON mapping defined in
{{Appendix E of CDDL}} SHOULD be employed.


### Supporting JSON Text Sequences in tooling

Note that JSON Text Sequences are not supported in most default programming
environments (unlike normal JSON). However, several custom JSON-SEQ parsing
libraries exist in most programming languages that can be used and the format is
easy enough to parse with existing implementations (i.e., by splitting the file
into its component records and feeding them to a normal JSON parser individually,
as each record by itself is a valid JSON object).

## JSON Interoperability {#json-interop}

Some JSON implementations have issues with the full JSON format, especially those
integrated within a JavaScript environment (e.g., Web browsers, NodeJS). I-JSON
(Internet-JSON) is a subset of JSON for such environments; see
{{!I-JSON=RFC7493}}. One of the key limitations of JavaScript, and thus I-JSON,
is that it cannot represent full 64-bit integers in standard operating mode
(i.e., without using BigInt extensions), instead being limited to the range
-(2<sup>53</sup>)+1 to (2<sup>53</sup>)-1.

To accommodate such constraints in CDDL, {{Appendix E of CDDL}} recommends
defining new CDDL types for int64 and uint64 that limit their values to the
restricted 64-bit integer range. However, some of the protocols that qlog is
intended to support (e.g., QUIC, HTTP/3), can use the full range of uint64
values.

As such, to support situations where I-JSON is in use, seralizers MAY encode
uint64 values using JSON strings. qlog parsers, therefore, SHOULD support
parsing of uint64 values from JSON strings or JSON numbers unless there is out-of-band
information indicating that neither the serializer nor parser are constrained by
I-JSON.

## Truncated values {#truncated-values}

For some use cases (e.g., limiting file size, privacy), it can be
necessary not to log a full raw blob (using the `hexstring` type) but
instead a truncated value. For example, one might only store the first 100 bytes of an
HTTP response body to be able to discern which file it actually
contained. In these cases, the original byte-size length cannot be
obtained from the serialized value directly.

As such, all qlog schema definitions SHOULD include a separate,
length-indicating field for all fields of type `hexstring` they specify,
see for example {{raw-info}}. This not only ensures the original length
can always be retrieved, but also allows the omission of any raw value
bytes of the field completely (e.g., out of privacy or security
considerations).

To reduce overhead however and in the case the full raw value is logged,
the extra length-indicating field can be left out. As such, tools MUST
be able to deal with this situation and derive the length of the field
from the raw value if no separate length-indicating field is present.
The main possible permutations are shown by example in
{{truncated-values-ex}}.

~~~~~~~~
// both the content's value and its length are present
// (length is redundant)
{
    "content_length": 5,
    "content": "051428abff"
}

// only the content value is present, indicating it
// represents the content's full value. The byte
// length is obtained by calculating content.length / 2
{
    "content": "051428abff"
}

// only the length is present, meaning the value
// was omitted
{
    "content_length": 5,
}

// both value and length are present, but the lengths
// do not match: the value was truncated to
// the first three bytes.
{
    "content_length": 5,
    "content": "051428"
}
~~~~~~~~
{: #truncated-values-ex title="Example for serializing truncated
hexstrings"}

## Optimization of serialized data {#optimizations}

Both the JSON and JSON-SEQ formatting options described above are serviceable in
general small to medium scale (debugging) setups. However, these approaches tend
to be relatively verbose, leading to larger file sizes. Additionally, generalized
JSON(-SEQ) (de)serialization performance is typically (slightly) lower than that
of more optimized and predictable formats. Both aspects present challenges to
large scale setups, though they may still be practical to deploy; see [ANRW-2020].
JSON and JSON-SEQ compress very well using commonly-available algorithms such as
GZIP or Brotli.

During the development of qlog, a multitude of alternative formatting
and optimization options were assessed and the results are [summarized on the qlog
github
repository](https://github.com/quiclog/internet-drafts/issues/30#issuecomment-617675097).

Formal definition of additional qlog formats or encodings that use the
optimization techniques described here, or any other optimization technique is
left to future activity that can apply the following guidelines.

In order to help tools correctly parse and process serialized qlog, it is
RECOMMENDED that new formats also define suitable file extensions and media
types. This provides a clear signal and avoids the need to provide out-of-band
information or to rely on heuristic fallbacks; see {{tooling}}.

# Methods of access and generation

Different implementations will have different ways of generating and storing
qlogs. However, there is still value in defining a few default ways in which to
steer this generation and access of the results.

## Set file output destination via an environment variable

To provide users control over where and how qlog files are created, two
environment variables are defined. The first, QLOGFILE, indicates a full path to where an
individual qlog file should be stored. This path MUST include the full file
extension. The second, QLOGDIR, sets a general directory path in which qlog files
should be placed. This path MUST include the directory separator character at the
end.

In general, QLOGDIR should be preferred over QLOGFILE if an endpoint is prone to
generate multiple qlog files. This can for example be the case for a QUIC server
implementation that logs each QUIC connection in a separate qlog file. An
alternative that uses QLOGFILE would be a QUIC server that logs all connections in
a single file and uses the "group_id" field ({{group-ids}}) to allow post-hoc
separation of events.

Implementations SHOULD provide support for QLOGDIR and MAY provide support for
QLOGFILE.

When using QLOGDIR, it is up to the implementation to choose an appropriate naming
scheme for the qlog files themselves. The chosen scheme will typically depend on
the context or protocols used. For example, for QUIC, it is recommended to use the
Original Destination Connection ID (ODCID), followed by the vantage point type of
the logging endpoint. Examples of all options for QUIC are shown in
{{qlogdir-example}}.

~~~~~~~~
Command: QLOGFILE=/srv/qlogs/client.qlog quicclientbinary

Should result in the the quicclientbinary executable logging a
single qlog file named client.qlog in the /srv/qlogs directory.
This is for example useful in tests when the client sets up
just a single connection and then exits.

Command: QLOGDIR=/srv/qlogs/ quicserverbinary

Should result in the quicserverbinary executable generating
several logs files, one for each QUIC connection.
Given two QUIC connections, with ODCID values "abcde" and
"12345" respectively, this would result in two files:
/srv/qlogs/abcde_server.qlog
/srv/qlogs/12345_server.qlog

Command: QLOGFILE=/srv/qlogs/server.qlog quicserverbinary

Should result in the the quicserverbinary executable logging
a single qlog file named server.qlog in the /srv/qlogs directory.
Given that the server handled two QUIC connections before it was
shut down, with ODCID values "abcde" and "12345" respectively,
this would result in event instances in the qlog file being
tagged with the "group_id" field with values "abcde" and "12345".
~~~~~~~~
{: #qlogdir-example title="Environment variable examples for a QUIC implementation"}

# Tooling requirements {#tooling}

Tools ingestion qlog MUST indicate which qlog version(s), qlog format(s),
compression methods and potentially other input file formats (for example .pcap)
they support. Tools SHOULD at least support .qlog files in the default JSON format
({{format-json}}). Additionally, they SHOULD indicate exactly which values for and
properties of the name (category and type) and data fields they look for to
execute their logic. Tools SHOULD perform a (high-level) check if an input qlog
file adheres to the expected qlog schema. If a tool determines a qlog file does
not contain enough supported information to correctly execute the tool's logic, it
SHOULD generate a clear error message to this effect.

Tools MUST NOT produce breaking errors for any field names and/or values in the
qlog format that they do not recognize. Tools SHOULD indicate even unknown event
occurrences within their context (e.g., marking unknown events on a timeline for
manual interpretation by the user).

Tool authors should be aware that, depending on the logging implementation, some
events will not always be present in all traces. For example, using a circular
logging buffer of a fixed size, it could be that the earliest events (e.g.,
connection setup events) are later overwritten by "newer" events. Alternatively,
some events can be intentionally omitted out of privacy or file size
considerations. Tool authors are encouraged to make their tools robust enough to
still provide adequate output for incomplete logs.

# Security and privacy considerations {#privacy}

Protocols such as TLS {{?RFC8446}} and QUIC {{?RFC9000}} offer secure protection
for the wire image {{?RFC8546}}. Logging can reveal aspects of the wire image
that would ordinarily be protected, creating tension between observability,
security and privacy, especially if data can be correlated across data sources.

Depending on the observability use case any data could be logged or captured. As
per {{?RFC6973}}, operators must be aware that such data could be compromised,
risking the privacy of all participants. Entities that expect protocol
features to ensure data privacy might unknowingly be subject to broader privacy
risks, undermining their ability to assess or respond effectively.

## Data at risk

qlog operators and implementers need to consider security and privacy risks when
handling qlog data, including logging, storage, usage, and more. The
considerations presented in this section may pose varying risks depending on the
the data itself or its handling.

The following is a non-exhaustive list of example data types that could contain
sensitive information that might allow identification or correlation of
individual connections, endpoints, users or sessions across qlog or other data
sources (e.g., captures of encrypted packets):

* IP addresses and transport protocol port numbers.

* Session, Connection, or User identifiers e.g., QUIC Connection IDs {{Section
  9.5 of !RFC9000}}).

* System-level information e.g., CPU, process, or thread identifiers.

* Stored State e.g., QUIC address validation and retry tokens, TLS session
  tickets, and HTTP cookies.

* TLS decryption keys, passwords, and HTTP-level API access or authorization tokens.

* High-resolution event timestamps or inter-event timings, event counts, packet
  sizes, and frame sizes.

* Full or partial raw packet and frame payloads that are encrypted.

* Full or partial raw packet and frame payloads that are plaintext e.g., HTTP Field
  values, HTTP response data, or TLS SNI field values.

## Operational implications and recommendations

Operational considerations should focus on authorizing capture and access to logs. Logging of
Internet protocols using qlog can be equivalent to the ability to store or read plaintext
communications. Without a more detailed analysis, all of the security considerations of plaintext access apply.

It is recommended that qlog capture is subject to access control and auditing.
These controls should support granular levels of information capture based on
role and permissions (e.g., capture of more-sensitive data requires higher
privileges).

It is recommended that access to stored qlogs is subject to access control and
auditing.

End users might not understand the implications of qlog to security or privacy,
and their environments might limit access control techniques. Implementations should
make enabling qlog conspicuous (e.g., requiring clear and explicit actions to
start a capture) and resistant to social engineering, automation, or drive-by
attacks; for example, isolation or sandboxing of capture from other activities
in the same process or component.

It is recommended that data retention policies are defined for the storage of
qlog files.

It is recommended that qlog files are encrypted in transit and at rest.

## Data minimization or anonymization

Applying data minimization or anonymization techniques to qlog might help
address some security and privacy risks. However, removing or anonymizing data
without sufficient care might not enhance privacy or security and
could diminish the utility of qlog data.

Operators and implementers should balance the value of logged data with the
potential risks of (involuntary) disclosure, which can depend on use cases
(e.g., research datasets might have different requirements to live operational
troubleshooting).

The most extreme form of minimization or anonymization is deleting a field,
equivalent to not logging it. qlog implementations should offer fine-grained
control for this on a per-use-case or per-connection basis.

Data can undergo anonymization, pseudonymization, permutation, truncation,
re-encryption, or aggregation; see {{Appendix B of !DNS-PRIVACY=RFC8932}} for
techniques, especially regarding IP addresses. However, operators should be
cautious because many anonymization methods have been shown to be insufficient to safeguard
user privacy or identity, particularly with large or easily correlated data sets.

Operators should consider end user rights and preferences. Active user participation (as
indicated by {{!RFC6973}}) on a per-qlog basis is challenging but aligning qlog
capture, storage, and removal with existing user preference and privacy controls
is crucial. Operators should consider agressive approaches to deletion or
aggregation.

The most sensitive data in qlog is typically contained in RawInfo type fields
(see {{raw-info}}). Therefore, qlog users should exercise caution and limit the
inclusion of such fields for all but the most stringent use cases.

# IANA Considerations {#iana}

TODO: file and event schema registration stuff

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

## Since draft-ietf-quic-qlog-main-schema-07:
{:numbered="false"}

* Added path and PathID (#336)
* Removed custom definition of uint64 type (#360, #388)
* ProtocolEventBody is now called ProtocolEventData (#352)
* Editorial changes (#364, #289, #353, #361, #362)

## Since draft-ietf-quic-qlog-main-schema-06:
{:numbered="false"}

* Editorial reworking of the document (#331, #332)
* Updated IANA considerations section (#333)

## Since draft-ietf-quic-qlog-main-schema-05:
{:numbered="false"}

* Updated qlog_version to 0.4 (due to breaking changes) (#314)
* Renamed 'transport' category to 'quic' (#302)
* Added 'system_info' field (#305)
* Removed 'summary' and 'configuration' fields (#308)
* Editorial and formatting changes (#298, #303, #304, #316, #320, #321, #322, #326, #328)

## Since draft-ietf-quic-qlog-main-schema-04:
{:numbered="false"}

* Updated RawInfo definition and guidance (#243)

## Since draft-ietf-quic-qlog-main-schema-03:
{:numbered="false"}

* Added security and privacy considerations discussion (#252)

## Since draft-ietf-quic-qlog-main-schema-02:
{:numbered="false"}

* No changes - new draft to prevent expiration

## Since draft-ietf-quic-qlog-main-schema-01:
{:numbered="false"}

* Change the data definition language from TypeScript to CDDL (#143)

## Since draft-ietf-quic-qlog-main-schema-00:
{:numbered="false"}

* Changed the streaming serialization format from NDJSON to JSON Text Sequences
  (#172)
* Added Media Type definitions for various qlog formats (#158)
* Changed to semantic versioning

## Since draft-marx-qlog-main-schema-draft-02:
{:numbered="false"}

* These changes were done in preparation of the adoption of the drafts by the QUIC
  working group (#137)
* Moved RawInfo, Importance, Generic events and Simulation events to this document.
* Added basic event definition guidelines
* Made protocol_type an array instead of a string (#146)

## Since draft-marx-qlog-main-schema-01:
{:numbered="false"}

* Decoupled qlog from the JSON format and described a mapping instead (#89)
    * Data types are now specified in this document and proper definitions for
      fields were added in this format
    * 64-bit numbers can now be either strings or numbers, with a preference for
      numbers (#10)
    * binary blobs are now logged as lowercase hex strings (#39, #36)
    * added guidance to add length-specifiers for binary blobs (#102)
* Removed "time_units" from Configuration. All times are now in ms instead (#95)
* Removed the "event_fields" setup for a more straightforward JSON format
  (#101,#89)
* Added a streaming option using the NDJSON format (#109,#2,#106)
* Described optional optimization options for implementers (#30)
* Added QLOGDIR and QLOGFILE environment variables, clarified the .well-known URL
  usage (#26,#33,#51)
* Overall tightened up the text and added more examples

## Since draft-marx-qlog-main-schema-00:
{:numbered="false"}

* All field names are now lowercase (e.g., category instead of CATEGORY)
* Triggers are now properties on the "data" field value, instead of separate field
  types (#23)
* group_ids in common_fields is now just also group_id

