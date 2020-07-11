---
title: Main logging schema for qlog
docname: draft-marx-qlog-main-schema-latest
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
    org: Hasselt University
    email: robin.marx@uhasselt.be

normative:
  RFC2119:
  QLOG-QUIC-HTTP3:
    title: "QUIC and HTTP/3 event definitions for qlog"
    date: 2019-10-14
    seriesinfo:
      Internet-Draft: draft-marx-qlog-event-definitions-quic-h3-01
    author:
      -
        ins: R. Marx
        name: Robin Marx
        org: Hasselt University
        role: editor

informative:

--- abstract

This document describes a high-level schema for a standardized logging format
called qlog.  This format allows easy sharing of data and the creation of reusable
visualization and debugging tools. The high-level schema in this document is
intended to be protocol-agnostic. Separate documents specify how the format should
be used for specific protocol data. The schema is also format-agnostic, and can be
represented in for example JSON, csv or protobuf.

--- middle

# Introduction

There is currently a lack of an easily usable, standardized endpoint logging
format. Especially for the use case of debugging and evaluating modern web
protocols and their performance, it is often difficult to obtain structured logs
that provide adequate information for tasks like problem root cause analysis.

This document aims to provide a high-level schema and harness that describes the
general layout of an easily usable, shareable, aggregatable and structured logging
format. This high-level schema is protocol agnostic, with logging entries for
specific protocols and use cases being defined in other documents (see for example
[QLOG-QUIC-HTTP3] for QUIC and HTTP/3-related event definitions).

The goal of this high-level schema is to provide amenities and default
characteristics that each logging file should contain (or should be able to
contain), such that generic and reusable toolsets can be created that can deal
with logs from a variety of different protocols and use cases.

As such, this document contains concepts such as versioning, metadata inclusion,
log aggregation, event grouping and log file size reduction techniques.

Feedback and discussion welcome at
[https://github.com/quiclog/internet-drafts](https://github.com/quiclog/internet-drafts).
Readers are advised to refer to the "editor's draft" at that URL for an
up-to-date version of this document.

## Notational Conventions {#data_types}

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC2119].

While the qlog schema's are format-agnostic, for readability the qlog documents
will use a JSON-inspired format for examples and definitions.

As qlog can be used both for purely textual but also binary formats, we employ a
custom datatype definition language, inspired loosely by the ["TypeScript"
language](https://www.typescriptlang.org/).

Other documents will describe how to transform the qlog schema into a specific
format. We include an example of such a transformation for JSON and discuss
options for binary formatting and optimization in {{concrete-formats}}.

The main general conventions a reader should be aware of are:

* obj? : this object is optional
* type1 &#124; type2 : a union of these two types (object can be either type1 OR
  type2)
* obj&#58;type : this object has this concrete type
* obj&#58;array&lt;type&gt; : this object is an array of this type
* class : defines a new type
* &#47;&#47; : single-line comment

The main data types are:

* int32 : signed 32-byte integer
* int64 : signed 64-byte integer
* uint32 : unsigned 32-byte integer
* uint64 : unsigned 64-byte integer
* float : 32-byte floating point value
* double : 64-byte floating point value
* byte : an individual raw byte value (use array&lt;byte&gt; to specify a binary blob)
* string : list of ASCII encoded characters
* boolean : boolean
* enum: fixed list of values (Unless explicity defined, the value of an enum entry
  is the string version of its name (e.g., initial = "initial"))
* any : represents any object type. Mainly used here as a placeholder for more
  concrete types defined in related documents (e.g., specific event types)

All timestamps in qlog are logged as UNIX epoch timestamps as uint64 in the
millisecond resolution. All other time-related values (e.g., offsets) are also
always expressed in milliseconds.

Other qlog documents can define their own types (e.g., separately for each Packet
type a protocol supports).

# Design Goals

The main tenets for the qlog schema design are:

* Streamable, event-based logging
* Flexibility in the format, complexity in the tooling (e.g., few components are a
  MUST, tools need to deal with this)
* Extensible and pragmatic (e.g., no complex fixed schema with extension points)
* Aggregation and transformation friendly (e.g., the top-level element is a
  container for individual traces)
* Metadata is stored together with event data


# The High Level Schema

A qlog file should be able to contain several indivdual traces and logs from
multiple vantage points that are in some way related. To that end, the top-level
element in the qlog schema defines only a small set of fields and an array of
component traces. For this document, the "qlog_version" field MUST have a value of
"draft-02-RC1".

~~~~~~~~
Definition:

class LogFile {
    qlog_version:string,
    title?:string,
    description?:string,
    summary?: Summary,
    traces: array<Trace|TraceError>
}

JSON example:
{
    "qlog_version": "draft-02-RC1",
    "title": "Name of this particular qlog file (short)",
    "description": "Description for this group of traces (long)",
    "summary": {
        ...
    }
    "traces": [...]
}
~~~~~~~~
{: .language-json}
{: #top_element title="Top-level element"}

## Summary field

In a real-life deployment with a large amount of generated logs, it can be useful
to sort and filter logs based on some basic summarized or aggregated data (e.g.,
log length, packet loss rate, log location, presence of error events, ...). The
summary field (if present) SHOULD be on top of the qlog file, as this allows for
the file to be processed in a streaming fashion (i.e., the implementation could
just read up to and including the summary field and then only load the full logs
that are deemed interesting by the user).

As the summary field is highly deployment-specific, this document does not specify
any default fields or their semantics. Some examples of potential entries are:

~~~
class Summary {
    // list of fields with any type
}

JSON example:
{
    "trace_count":uint32, // amount of traces in this file
    "max_duration":uint64, // time duration of the longest trace
    "max_outgoing_loss_rate":float, // highest loss rate for outgoing packets over all traces
    "total_event_count":uint64, // total number of events across all traces,
    "error_count":uint64 // total number of error events in this trace
}
~~~
{: .language-json}
{: #summary title="Summary example definition"}


## Traces field

The "traces" array contains a list of individual qlog traces. Typical logs will
only contain a single element in this array. Multiple traces can however be
combined into a single qlog file by taking the "traces" entries for each qlog file
individually and copying them to the "traces" array of a new, aggregated qlog
file. This is typically done in a post-processing step.

For example, for a test setup, we perform logging on the client, on the server and
on a single point on their common network path. Each of these three logs is first
created separately during the test. Afterwards, the three logs can be aggregated
into a single qlog file.

For the definition of the Trace type, see {{trace}}.

As such, the "traces" array can also contain "error" entries. These indicate that
we tried to find/convert a file for inclusion in the aggregated qlog, but there
was an error during the process. Rather than silently dropping the erroneous file,
we can opt to explicitly include it in the qlog file as an entry in the "traces"
array.

~~~
Definition:
class TraceError {
    error_description: string,
    uri?: string,
    vantage_point?: VantagePoint
}

JSON example:
{
    "error_description": "A description of the error (e.g., file could not be found, file had errors, ...)",
    "uri": "the original URI at which we attempted to find the file",
    "vantage_point": see {{vantage_point}} // the vantage point we were expecting to include here
}
~~~
{: .language-json}
{: #traceerror title="TraceError definition"}


## Individual Trace containers {#trace}

Each indidivual trace container encompasses a single conceptual trace. The exact
definition of a trace can be fluid. For example, a trace could contain all events
for a single connection, for a single endpoint, for a single measurement interval,
etc.

In the normal use case, a trace is a log of a single data flow collected at a
single location or vantage point. For example, for QUIC, a single trace only
contains events for a single logical QUIC connection for either the client or the
server. However, a single trace could also combine events from a variety of
vantage points or use cases (e.g., a middlebox could group events from all
observed connections into a single trace).

The semantics and context of the trace can be deduced from the entries in the
"common_fields" (specifically the "group_id" field) and "event_fields" lists.

~~~~~~~~
Definition:
class Trace {
    title?: string,
    description?: string,
    configuration?: Configuration,
    common_fields?: CommonFields,
    event_fields?: array<string>,
    vantage_point: VantagePoint,
    events: array<Event>
}

JSON example:
{
    "title": "Name of this particular trace (short)",
    "description": "Description for this trace (long)",
    "configuration": {
        "time_offset": 150
    },
    "common_fields": {
        "ODCID": "be12"
    },
    "event_fields": (see below),
    "vantage_point": {
        "name": "backend-67",
        "type": "server"
    },
    "events": [...]
}
~~~~~~~~
{: .language-json}
{: #trace_container title="Trace container definition"}

### Configuration

We take into account that a log file is usually not used in isolation, but by
means of various tools. Especially when aggregating various traces together or
preparing traces for a demonstration, one might wish to persist certain tool-based
settings inside the log file itself. For this, the configuration field is used.

The configuration field can be viewed as a generic metadata field that tools can
fill with their own fields, based on per-tool logic. It is best practice for tools
to prefix each added field with their tool name to prevent collisions across
tools. This document only defines two optional, standard, tool-independent
configuration settings: "time_offset" and "original_uris".

~~~~~~~~
Definition:
class Configuration {
    time_offset:uint64, // in milliseconds,
    original_uris: array<string>,
    // list of fields with any type
}

Example:
{
    "time_offset": 150, // starts 150ms after the first timestamp indicates
    "original_uris": [
        "https://example.org/trace1.qlog",
        "https://example.org/trace2.qlog"
    ]
}
~~~~~~~~
{: .language-json}
{: #configuration_example title="Configuration definition"}


#### time_offset
time_offset indicates by how many milliseconds the starting time of the current
trace should be offset. This is useful when comparing logs taken from various
systems, where clocks might not be perfectly synchronous. Users could use manual
tools or automated logic to align traces in time and the found optimal offsets can
be stored in this field for future usage. The default value is 0.

#### original_uris
This field is used when merging multiple individual qlog files or other source
files (e.g., when converting .pcaps to qlog). It allows to keep better track where
certain data came from. It is a simple array of strings. It is an array instead of
a single string, since a single qlog trace can be made up out of an aggregation of
multiple component qlog traces as well. The default value is an empty array.


#### custom fields
Tools can add optional custom metadata to the "configuration" field to store state
and make it easier to share specific data viewpoints and view configurations.

An example from the [qvis toolset](https://qvis.edm.uhasselt.be)'s congestion
graph follows. In this example, the congestion graph is zoomed in between 1s and
2s of the trace and the 124th event in the trace is selected.

~~~
{
    "configuration" : {
        "time_offset": 100,
        "qvis" : {
            "congestiongraph": {
                "startX": 1000,
                "endX": 2000,
                "selectedEvent": 124
            }
        }
    }
}
~~~
{: #qvis_config title="Custom configuration fields example"}

### vantage_point {#vantage-point}

This field describes the vantage point from which the trace originates. Each trace
can have only a single vantage_point and thus all events in a trace MUST BE from
the perspective of this vantage_point. To include events from multiple
vantage_points, implementers can include multiple traces, split by vantage_point,
in a single qlog file.

~~~~~~~~
Definition:
class VantagePoint {
    name?: string,
    type: VantagePointType,
    flow?: VantagePointType
}

class VantagePointType {
    server, // endpoint which initiates the connection.
    client, // endpoint which accepts the connection.
    network, // observer in between client and server.
    unknown
}

JSON examples:
{
    "name": "aioquic client",
    "type": "client",
}

{
    "name": "wireshark trace",
    "type": "network",
    "flow": "client"
}
~~~~~~~~
{: .language-json}
{: #vantage_point title="VantagePoint definition"}

The flow field is only required if type is "network" (for example, the trace is
generated from a packet capture). It is used to disambiguate events like
"packet sent" and "packet received". This is indicated explicitly because for
multiple reasons (e.g., privacy) data from which the flow direction can be
otherwise inferred (e.g., IP addresses) might not be present in the logs.

Meaning of the different values for the flow field:
  * "client" indicates that this vantage point follows client data flow semantics (a
    "packet sent" event goes in the direction of the server).
  * "server" indicates that this vantage point follow server data flow semantics (a
    "packet sent" event goes in the direction of the client).
  * "unknown" indicates that the flow is unknown.

Depending on the context, tools confronted with "unknown" values in the
vantage_point can either try to infer the semantics from protocol-level domain
knowledge (e.g., in QUIC, the client always sends the first packet) or give the
user the option to switch between client and server perspectives manually.

### common_fields and event_fields

To reduce file size and make logging easier, the trace schema lists the names of
the specific fields that are logged per-event up-front, instead of repeating the
field name with each value, as is common in traditiona JSON. This is done in the
"event_fields" list. This allows us to encode individual events as an array of
values, instead of an object. To reduce file size even further, common event
fields that have the same value for all events in this trace, are listed as
name-value pairs in "common_fields".

For example, when logging events for a single QUIC connection, all events will
share the same "original destination connection ID" (ODCID). This field and its
value should be set in "common_fields", rather than "event_fields". However, if a
single trace would contain events for multiple QUIC connections at the same time
(e.g., a single, big output log for a server), the ODCID can be different across
events, and should be part of "event_fields" instead (leading to it being logged
for each individual event).

Examples comparing traditional JSON vs the qlog format can be found in
{{traditional_json}} and {{qlog_json}}. The events described in these examples are
purely for illustration. Actual event type definitions for the QUIC and HTTP/3
protocols can be found in [QLOG-QUIC-HTTP3].

~~~~~~~~
{
    "events": [{
            "group_id": "127ecc830d98f9d54a42c4f0842aa87e181a",
            "ODCID": "127ecc830d98f9d54a42c4f0842aa87e181a",
            "protocol_type": "QUIC_HTTP3",
            "time": 1553986553574,
            "category": "transport",
            "event": "packet_received",
            "data": [...]
        },{
            "group_id": "127ecc830d98f9d54a42c4f0842aa87e181a",
            "ODCID": "127ecc830d98f9d54a42c4f0842aa87e181a",
            "protocol_type": "QUIC_HTTP3",
            "time": 1553986553579,
            "category": "http",
            "event": "frame_parsed",
            "data": [...]
        },
        ...
    ]
}
~~~~~~~~
{: .language-json}
{: #traditional_json title="Traditional JSON"}


~~~~~~~~
{
    "common_fields": {
        "group_id": "127ecc830d98f9d54a42c4f0842aa87e181a",
        "ODCID": "127ecc830d98f9d54a42c4f0842aa87e181a",
        "protocol_type":  "QUIC_HTTP3",
        "reference_time": "1553986553572"
    },
    "event_fields": [
        "relative_time",
        "category",
        "event",
        "data"
    ],
    "events": [[
            2,
            "transport",
            "packet_received",
            [...]
        ],[
            7,
            "http",
            "frame_parsed",
            [...]
        ],
        ...
    ]
}
~~~~~~~~
{: .language-json}
{: #qlog_json title="qlog optimized JSON"}

The main field names that can be included in these fields are defined in
{{field-name-semantics}}.

Given that qlog is intended to be a flexible format, unknown field names in both
"common_fields" and "event_fields" MUST be disregarded by the user and tools
(i.e., the presence of an uknown field is explicitly NOT an error).

This approach makes line-per-line logging easier and faster, as each log statement
only needs to include the data for the events, not the field names. Events can
also be logged and processed separately, as part of a contiguous event-stream.

#### common_fields format

An object containing pairs of "field name"-"field value". Fields included in
"common_fields" indicate that these field values are the same for each event in
the "events" array.

If even one event in the trace does not adhere to this convention, that field name
should be in "event_fields" instead, and the value logged per event. An
alternative route is to include the most commonly seen value in "common_fields"
and then include the deviating field value in the generic "data" field for each
non-confirming event. However, these semantics are not defined in this document.

#### event_fields format

An array of field names (plain strings). Field names included in "event_fields"
indicate that these field names are present **in this exact order** for each event
in the "events" array. Each individual event then only has to log the
corresponding values for those fields in the correct order.

## Field name semantics {#field-name-semantics}

This section lists pre-defined, reserved field names with specific semantics and
expected corresponding value formats.

Only one time-based field (see {{time-based-fields}}), the "event" field and the
"data" field are mandatory. Typical setups will log "reference_time",
"protocol_type" and "group_id" in "common_fields" and "relative_time", "category",
"event" and "data" in "event_fields".

Other field names are allowed, both in "common_fields" and "event_fields", but
their semantics depend on the context of the log usage (e.g., for QUIC, the ODCID
field is used), see [QLOG-QUIC-HTTP3].



~~~~~~~~
Definition:
 {
    protocol_type: string,
    group_id?:array<string>, // if in common_fields
    group_id?:string|uint32, // if per-event

    // at least one of these four fields must be present
    time?: uint64,
    reference_time?: uint64,
    relative_time?: uint64,
    delta_time?: uint64,

    category: string,
    event: string,
    data: any,

    // list of fields with any type
}

JSON example:
{
    "protocol_type":  "QUIC_HTTP3",
    "group_id": ["127ecc830d98f9d54a42c4f0842aa87e181a"],

    "time": 1553986553572,
    "reference_time": 1553986553572,
    "relative_time": 125,
    "delta_time": 5,

    "category": "transport",
    "event": "packet_sent",
    "data": { ... }

    "ODCID": "127ecc830d98f9d54a42c4f0842aa87e181a",
}
~~~~~~~~
{: .language-json}
{: #event_fields title="Event fields definition"}

### timestamps {#time-based-fields}

There are three main modes for logging time:

* Include the full timestamp with each event ("time"). This approach uses the
  largest amount of characters.
* Delta-encode each time value on the previously logged value ("delta_time").
  The first event can log the full timestamp. This approach uses the least amount
  of characters.
* Specify a full "reference_time" timestamp up-front in "common_fields" and
  include only relatively-encoded values based on this reference_time with each
  event ("relative_time"). This approach uses a medium amount of characters.

The first option is good for stateless loggers, the second and third for stateful
loggers. The third option is generally preferred, since it produces smaller files
while being easier to reason about.

~~~
The time approach will use:
1500, 1505, 1522, 1588

The delta_time approach will use:
1500, 5, 17, 66

The relative_time approach will:
- set the reference_time to 1500 in "common_fields"
- use: 0, 5, 22, 88

~~~
{: #time_approaches title="Three different approaches for logging timestamps"}

One of these options should be chosen for the entire trace. Each event MUST
include a timestamp.

Events in each individual trace SHOULD be logged in strictly ascending timestamp
order (though not necessarily absolute value, for the "delta_time" setup). Tools
CAN sort all events on the timestamp before processing them, though are not
required to (as this could impose a significant processing overhead).

### group_id {#group_ids}

A single Trace can contain events from a variety of sources, belonging to for
example a number of individual QUIC connections. For tooling considerations, it is
necessary to have a well-defined way to split up events belonging to different
logical groups into subgroups for visualization and processing. For example, if
one type of log uses 4-tuples as identifiers and uses a field name "four_tuple"
and another uses "ODCID", there is no way to know for generic tools which of these
fields should be used to create subgroups. As such, qlog uses the generic
"group_id" field to circumvent this issue.

The "group_id" field is always an array of strings. For more complex use cases, in
which the the group_id's internally are complex objects with several fields (e.g.,
a 4-tuple per group), this complex value should be serialized. In those
cases, it would be wasteful to log these values in full every single time. This
would also complicate tool-based processing.


qlog typically expects to find the "group_id" field in both "common_fields" and
"event_fields" **at the same time** (where normally, a field is only allowed in
one of both). In this case, the per-event value of the "group_id" field represents
an index in to the group_id array in "common_fields". This is useful if the
group_ids are known up-front or the qlog trace can be generated from a more
verbose format afterwards. If this is not the case however, it is acceptable to
just log the full serialized group_id for each event and to not include "group_id"
in "common_fields". Both use cases are demonstrated in {{group_id_repeated}} and
{{group_id_indexed}}. The final option is not to include the "group_id" int each
event but rather have a "group_id" array with a single entry in "common_fields".
This is useful when all events in a trace belong to the same group, but you still
want to keep track of the group_id explicitly.

Since "group_id" is a generic name, it conveys little of the semantics to the
casual reader. It is best practice to also include a per use case additional field
to the "common_fields" with a semantic name, that has the same value as the
"group_id" field. For example, see the "ODCID" field in {{qlog_json}} and the
"four_tuples" field in {{group_id_indexed}}.

~~~~~~~~
{
    "common_fields": {
        "protocol_type":  "QUIC_HTTP3",
    },
    "event_fields": [
        "time",
        "group_id",
        "category",
        "event",
        "data"
    ],
    "events": [[
            1553986553579,
            "ip1=2001:67c:1232:144:9498:6df6:f450:110b,ip2=2001:67c:2b0:1c1::198,port1=59105,port2=80"
            "transport",
            "packet_received",
            [...]
        ],[
            1553986553588,
            "ip1=10.0.6.137,ip2=52.58.13.57,port1=56522,port2=443"
            "http",
            "frame_parsed",
            [...]
        ],[
            1553986553598,
            "ip1=2001:67c:1232:144:9498:6df6:f450:110b,ip2=2001:67c:2b0:1c1::198,port1=59105,port2=80"
            "transport",
            "packet_sent",
            [...]
        ],
        ...
    ]
}
~~~~~~~~
{: .language-json}
{: #group_id_repeated title="Repeated complex group_id"}


~~~~~~~~
{
    "common_fields": {
        "protocol_type":  "QUIC_HTTP3",
        "group_id": [
            "ip1=2001:67c:1232:144:9498:6df6:f450:110b,ip2=2001:67c:2b0:1c1::198,port1=59105,port2=80"
            "ip1=10.0.6.137,ip2=52.58.13.57,port1=56522,port2=443"
        ],
        "four_tuples": [
            "ip1=2001:67c:1232:144:9498:6df6:f450:110b,ip2=2001:67c:2b0:1c1::198,port1=59105,port2=80"
            "ip1=10.0.6.137,ip2=52.58.13.57,port1=56522,port2=443"
        ]
    },
    "event_fields": [
        "time",
        "group_id",
        "category",
        "event",
        "data"
    ],
    "events": [[
            1553986553579,
            0,
            "transport",
            "packet_received",
            [...]
        ],[
            1553986553588,
            1,
            "http",
            "frame_parsed",
            [...]
        ],[
            1553986553598,
            0,
            "transport",
            "packet_sent",
            [...]
        ],
        ...
    ]
}
~~~~~~~~
{: .language-json}
{: #group_id_indexed title="Indexed complex group_id"}


### category and event

Category allows a higher-level grouping of events per specific event type.

For example, instead of having an event of value "transport_packet_sent", we
instead have a category of "transport" and event type of "packet_sent". This
allows for fast and high-level filtering based on category and re-use of event
across categories.

### data

The data field is a generic object. It contains the per-event metadata and its
form and semantics are defined per specific sort of event (typically per event,
but possibly also by combination of category and event). For example data field
value definitons for QUIC and HTTP/3, see [QLOG-QUIC-HTTP3].

### custom Fields

Note that qlog files can always contain custom fields (e.g., a per-event field
indicating its privacy properties or path_id in multipath protocols) and assign
custom values to existing fields (e.g., new categories for implemenation-specific
events). Loggers are free to add such fields and field values and tools MUST
either ignore these unknown fields or show them in a generic fashion.

### event field values

The specific values for each of these fields and their semantics are defined in
separate documents, specific per protocol or use case.

For example: event definitions for QUIC and HTTP/3 can be found in
[QLOG-QUIC-HTTP3].

## Triggers

Sometimes, additional information is needed in the case where a single event can
be caused by a variety of other events. In the normal case, the context of the
surrounding log messages gives a hint as to which of these other events was the
cause. However, in highly-parallel and optimized implementations, corresponding
log messages might be wide and far between in time. Another option is to use
triggers instead of logging extra full events to get more fine-grained information
without much additional overhead.

For this reason, qlog allows an optional "trigger" property on the value of the
"data" field to convey such information. It indicates the reason this event
occured. The possible reasons depend on the type of event and SHOULD be specified
next to each event definition. Triggers are always strings, though specific
protocols can add additional fields with more metadata on the triggering
conditions.

~~~~~~~~
{
    "common_fields": {
        "group_id": "127ecc830d98f9d54a42c4f0842aa87e181a",
        "ODCID": "127ecc830d98f9d54a42c4f0842aa87e181a",
        "protocol_type":  "QUIC_HTTP3",
        "reference_time": 1553986553572
    },
    "event_fields": [
        "relative_time",
        "category",
        "event",
        "data"
    ],
    "events": [[
            20,
            "transport",
            "packet_dropped",
            {
                // Indicates that the packet has been dropped because
                // there were no appropriate TLS keys available to decrypt
                // it at this time.
                "trigger": "keys_unavailable",
                ...
            }
        ],[
            27,
            "transport",
            "packet_sent",
            {
                // Indicates that this packet was sent as a probe after a timeout occurred
                "trigger": "pto_probe",
                ...
            }
        ],
        ...
    ]
}
~~~~~~~~
{: .language-json}
{: #trigger_example title="Trigger example"}

# Tooling requirements

Tools MUST indicate which qlog version(s) they support. Additionally, they SHOULD
indicate exactly which values for and properties of the category, event and data
fields they look for to execute their logic. Tools SHOULD perform a (high-level)
check if an input qlog file adheres to the expected qlog schema. If a tool
determines a qlog file does not contain enough supported information to correctly
execute the tool's logic, it SHOULD generate a clear error message to this effect.

Tools MUST NOT produce errors for any field names and values in the qlog format
that they do not recognize. Tools CAN indicate unknown event occurences within
their context (e.g., marking unknown events on a timeline for manual
interpretation by the user).

Tool authors should be aware that, depending on the logging implementation, some
events will not always be present in all traces. For example, using a circular
logging buffer of a fixed size, it could be that the earliest events (e.g.,
connection setup events) are later overwritten by "newer" events. Tool authors are
encouraged to take this setup into account and to make their tools robust enough
to still provide adequate output for incomplete logs. Loggers using a circular
buffer are in turn reminded of the requirement of listing events in strict time
order, as per {{time-based-fields}}.

Most JSON parsers strictly follow the JSON specification. This includes the rule
that trailing comma's are not allowed. As it is frequently annoying to remove
these trailing comma's when logging events in a streaming fashion, tool
implementers SHOULD allow the last event entry of a qlog trace to be an empty
array. This allows loggers to simply close the qlog file by appending "[]]}]}"
after their last streamed event.

# Methods of Access and Generation

This section describes some default ways to access and trigger generation of qlog
files.

## via a well-known endpoint

qlog implementers MAY make generated logs and traces on an endpoint (typically the
server) available via the following .well-known URI:

> .well-known/qlog/{IDENTIFIER}

The IDENTIFIER variable depends on the setup and the chosen protocol. For example,
for QUIC logging, the ODCID is often used to uniquely identify a connection.

Implementers SHOULD allow users to fetch logs for a given connection on a 2nd,
separate connection. This helps prevent pollution of the logs by fetching them
over the same connection that one wishes to observe through the log. Ideally, for
the QUIC use case, the logs should also be approachable via an HTTP/2 or HTTP/1.1
endpoint, to aid debugging.

qlog implementers SHOULD NOT enable this .well-known endpoint in typical
production settings to prevent (malicious) users from downloading logs from other
connections. Implementers are advised to disable this endpoint by default and
require specific actions from the end users to enable it (and potentially qlog
itself).


# Notes on Practical Use

Note that, even with the optimizations detailed above, it is to be expected that
qlog files (as they are JSON) will be relatively large when compared to binary
formats. If this turns out to be an issue in a real deployment, it is a perfectly
acceptable practices to first generate the initial application-side logs in
another (custom) (binary) format. Afterwards, those bespoke files can then be
transformed into the qlog format for improved interoperability with tools and
other logs. A prime example of this is converting of binary .pcap packet capture
files (e.g., obtained from wireshark or tcpdump) to the qlog format. [Such a
conversion tool is available for the QUIC and HTTP/3
protocols](https://github.com/quiclog/pcap2qlog).

# Guidance on Exporting qlog to a Concrete Format {#concrete-formats}

This document and other related qlog schema definitions are intentionally
format-agnostic. This means that implementers themselves can choose how to
represent and serialize qlog data practically on disk or on the wire. Some
examples of possible formats are JSON, CBOR, CSV, protocol buffers, flatbuffers,
etc. All these formats make certain tradeoffs between flexibility and efficiency,
with textual formats like JSON typically being more flexible than binary formats
like protocol buffers. The format choice will depend on the practical use case of
the qlog user. For example, for use in day to day debugging, a plaintext readable
(yet relatively large) format like JSON is probably preferred. However, for use in
production, a more optimized yet restricted format can be better. In this latter
case, it will be more difficult to achieve interoperability between qlog
implementations of various protocol stacks, as some custom or tweaked events from
one might not be compatible with the format of the other. This will also reflect
in tooling: not all tools will support all formats.

This being said, the authors prefer JSON as the basis for storing qlog, as it
retains full flexibility and maximum interoperability. For this reason, this
section details how to practically transform qlog schema definitions to JSON. We
also discuss options to bring down JSON size and processing overheads in
{{optimizations}}, which has made the JSON-based approach quite usable in many
practical situations.

## qlog to JSON mapping

To facilitate this mapping, the qlog document employ a format that is close to
pure JSON for its examples and data definitions. Still, as JSON is not a typed
format, there are some peculiarities to observe.

### Numbers

While JSON has built-in support for both strings and numbers up to 64 bits in
size, not all JSON parsers do. For example, none of the major Web browsers support
full 64-bit numbers at this time. Instead, all numbers are internally represented
as floating point values, with a maximum value of 2^53-1. Numbers larger than that
are either truncated or produce a JSON parsing error. While this is expected to
improve in the future (as "BigInt" support has been introduced in most Browsers),
we still need to deal with it here.

When transforming an int64, uint64 or double from qlog to JSON, the implementer
can thus choose to either log them as JSON numbers (taking the risk) or to log
them as strings instead. Logging as strings should however only be practically
needed if the value is likely to exceed 2^53-1. In practice, even though protocols
such as QUIC allow 64-bit values for for example stream identifiers, these high
numbers are unlikely to be reached for the overwhelming majority of cases. As
such, it is probably a valid trade-off to take the risk and log 64-bit values as
JSON numbers instead of strings.

Tools processing JSON-based qlog SHOULD be able to deal with 64-bit fields being
serialized as either strings or numbers.

### Bytes

Unlike most binary formats, JSON does not allow the logging of raw binary blobs
directly. As such, when serializing a byte or array&lt;byte&gt;, a scheme needs to
be chosen.

To represent qlog bytes in JSON, they MUST be serialized to their lowercase
hexadecimal format (with 0 prefix for values lower than 10). All values are
directly appended to each other, without delimiters. The full value is not
prefixed with 0x (as is sometimes common).

~~~~~~~~
For the five raw unsigned byte input values of: 5 20 40 83 255, the JSON serialization is:

{
    "raw": "05142853FF"
}
~~~~~~~~
{: .language-json}
{: #bytes_example title="Example for serializing bytes"}

As such, the resulting string will always have an even amount of characters and
the original byte-size can be retrieved by dividing the string length by 2.

#### Truncated Values

In some cases, it can be interesting not to log a full raw blob but instead a
truncated value (for example, only the first 100 bytes of an HTTP response body to
be able to discern which file it actually contained). In these cases, the original
byte-size length cannot be obtained from the serialized value directly. As such,
all qlog schema definitions SHOULD include a separate, length-indicating field for
all fields of type array&lt;byte&gt; they specify. This allows always retrieving
the original length, but also allows the omission of any raw value bytes of the
field completely (e.g., out of privacy or security considerations).

To reduce overhead however and in the case the full raw value is logged, the extra
length-indicating field can be left out. As such, tools MUST be able to deal with
this situation and derive the length of the field from the raw value if no
separate length-indicating field is present.

~~~~~~~~
// both the full raw value and its length are present (length is redundant)
{
    "raw_length": 5,
    "raw": "05142853FF"
}

// only the raw value is present, indicating it represents the fields full value
{
    "raw": "05142853FF"
}

// only the length field is present, meaning the value was omitted
{
    "raw_length": 5,
}

// both fields are present and the lengths do not match: the value was truncated to the first three bytes.
{
    "raw_length": 5,
    "raw": "051428"
}

~~~~~~~~
{: .language-json}
{: #bytes_example_two title="Example for serializing truncated bytes"}


### Summarizing table

JSON strings are serialized with quotes. Numbers without.

| qlog type | JSON type                             |
|-----------|---------------------------------------|
| int32     | number                                |
| uint32    | number                                |
| float     | number                                |
| int64     | number or string                      |
| uint64    | number or string                      |
| double    | number or string                      |
| bytes     | string (lowercase hex value)          |
| string    | string                                |
| boolean   | string ("true" or "false")            |
| enum      | string (full value/name, not index)   |
| any       | object  ( {...} )                     |
| array     | array   ( \[...\] )                   |


## Optimization options {#optimizations}

Besides moving to a stricter, binary format (such as protocol buffers), there are
various options to reduce the size of a JSON-based qlog format. As we as authors
believe JSON is the format best suited for qlog, we also formalize a few of these
optimization options here. Tools SHOULD support these if they intend to be useful
across protocol stacks.

TODO: common_fields as expected, default, no-brainer optimization
TODO: cbor and compression as recommended optimizations
TODO: event_fields as potential optimization
TODO: dictionary-based as potential optimization
TODO: protobuf or other binary format as potential optimization with flexibility caveat

TODO: link to discussion + reproduce results table here (first get resutls for the
non-event-field version of qlog though)


# Security Considerations

TODO : discuss privacy and security considerations (e.g., what NOT to log, what to
strip out of a log before sharing, ...)

# IANA Considerations

TODO: primarily the .well-known URI

--- back

# Change Log

## Since draft-marx-qlog-main-schema-01:

* Decoupled qlog from the JSON format and described a mapping instead (#89)
    * Data types are now specified in this document and proper definitions for
      fields were added in this format
    * 64-bit numbers can now be either strings or numbers, with a preference for
      numbers (#10)
    * binary blobs are now logged as lowercase hex strings (#39, #36)
    * added guidance to add length-specifiers for binary blobs (#102)
* Removed "time_units" from Configuration. All times are now in ms instead (#95)


## Since draft-marx-qlog-main-schema-00:

* All field names are now lowercase (e.g., category instead of CATEGORY)
* Triggers are now properties on the "data" field value, instead of separate field
  types (#23)
* group_ids in common_fields is now just also group_id

# Design Variations

* [Quic-trace](https://github.com/google/quic-trace) takes a slightly different
  approach based on protocolbuffers.
* [Spindump](https://github.com/EricssonResearch/spindump) also defines a custom
  text-based format for in-network measurements
* [Wireshark](https://www.wireshark.org/) also has a QUIC dissector and its
  results can be transformed into a json output format using tshark.

The idea is that qlog is able to encompass the use cases for both of these
alternate designs and that all tooling converges on the qlog standard.

# Acknowledgements

Thanks to Jana Iyengar, Brian Trammell, Dmitri Tikhonov, Stephen Petrides, Jari
Arkko, Marcus Ihlar, Victor Vasiliev, Mirja Kühlewind, Jeremy Lainé and Lucas
Pardue for their feedback and suggestions.

