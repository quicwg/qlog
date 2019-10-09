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

informative:

--- abstract

This document describes a high-level schema for a standardized endpoint logging
format called qlog.  This format allows easy sharing of data and the creation of
reusable visualization and debugging tools. The high-level schema in this document
is intended to be protocol-agnostic. Separate documents specify how the format
should be used for specific protocol data.

--- middle

# Introduction

Feedback and discussion welcome at https://github.com/quiclog/internet-drafts

## Notational Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC2119].

# Design Goals

The main tenets for the schema design are:

* Streamable, event-based
* Flexibility in the format, complexity in the tooling (e.g., few components are a
  MUST, tools need to deal with this)
* Extensible but pragmatic (e.g., no complex fixed schema with extension points)
* Aggregation and transformation friendly (e.g., the top-level element is a
  container for individual traces)
* Explicit and human-readable

# The High Level Schema

TODO: add proper data definitions for all fields (e.g., enums, strings vs numbers,
etc. similar to what we have in the other document). For now, if in doubt, refer
to https://github.com/quiclog/qlog/blob/master/TypeScript/draft-01/QLog.ts

## Top level container
To allow separate qlog traces to be contained within a single, encompassing qlog
file, the top-level element in the qlog schema defines only a small set of fields
and an array of component traces. Only the "qlog_version" and "traces" fields MUST
be present. For this document, the "qlog_version" field MUST have a value of
draft-00.

~~~~~~~~
{
    "qlog_version": "draft-00",
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

Typical logs will only contain a single element in the "traces" array. Multiple
traces can then be combined into a single qlog file by taking the "traces" entries
for each qlog file individually and copying them to the "traces" array of a new,
aggregated qlog file. This is typically done in a post-processing step.

For example, for a test setup, we perform logging on the client, on the server and
on a single point on their common network path. Each of these three logs is first
created separately during the test. Afterwards, the three logs can be aggregated
into a single qlog file.

As such, the "traces" array can also contain "error" entries. These indicate that
we tried to find/convert a file for inclusion in the aggregated qlog, but there
was an error during the process. Rather than silently dropping the erroneous file,
we explicitly include it in the qlog file.

TODO: add proper data definitions of what the "error" should look like

~~~
interface IError {
    error_description: string,
    uri: string
}
~~~

## Summary field

In a real-life deployment with a large amount of generated logs, it can be useful
to sort and filter logs based on some basic summarized or aggregated data (e.g.,
log length, packet loss rate, log location, ...). The summary field (if present)
SHOULD be on top of the qlog file, as this allows for the file to be processed in
a streaming fashion (i.e., the implementation could just read up to and including
the summary field and then only load the full logs that are deemed interesting by
the user).

As the summary field is highly deployment-specific, this document does not specify
any default fields or their semantics. Some examples of potential entries are:

~~~
"summary": {
    "trace_count":number, // amount of traces in this file
    "max_duration":string, // time duration of the longest trace
    "max_outgoing_loss_rate":number, // highest loss rate for outgoing packets over all traces
    "total_event_count":number // total number of events across all traces
}
~~~

* TODO: are there any field semantics we should specify here?
* TODO: Will people actually use this? or will they store this info out-of-band
  (e.g., separate database for faster querying?)

## Trace container
Each trace container encompasses a single conceptual trace. The exact definition
of a trace can be fluid. For example, a trace could contain all events for a
single connection, for a single endpoint, for a single measurement interval, ...

In the normal use case, a trace is a log of a single data flow collected at a
single location or vantage point. For example, for QUIC, a single trace only
contains events for a single logical QUIC connection. However, a single trace
could also combine events from a variety of vantage points or use cases (e.g.,
multiple QUIC connections or the same connection viewed from different points in
the network).

The semantics and context of the trace can be deduced from the entries in the
"common_fields" (specifically the "group_ids" field) and "event_fields" lists.

Only the "event_fields" and "events" fields MUST be present.

~~~~~~~~
{
    "vantage_point": {
        "name": "backend-67",
        "type": "server"
    },
    "title": "Name of this particular trace (short)",
    "description": "Description for this trace (long)",
    "configuration": {
        "time_offset": "offset in ms",
        "time_units": "ms" | "us"
    },
    "common_fields": (see below),
    "event_fields": (see below),
    "events": [...]
}
~~~~~~~~
{: .language-json}
{: #trace_container title="Trace container"}

### vantage_point

This field describes the vantage point from which the trace originates.
Its value is an object, with the following fields:

* name: an optional, user-chosen string (e.g., "NETWORK-1", "loadbalancer45",
  "reverseproxy@192.168.1.1", ...)
* type: one of four values: "server", "client", "network" or "unknown".

  * client indicates an endpoint which initiates the connection.
  * server indicates an endpoint which accepts the connection.
  * network indicates an observer in between client and server.
  * unknown indicates the endpoint is unknown.
* flow: one of three values: "client", "server" or "unknown".

  * This field is only required if type is "network".
  * client indicates that this vantage point follows client data flow semantics (a
    packet_sent goes in the direction of the server).
  * server indicates that this vantage point follow server data flow semantics (a
    packet_sent goes in the direction of the client).
  * unknown indicates that the flow is unknown.

The type field MUST be present. The flow field MUST be present if the type field
has value "network". The name field is optional.

TODO (see issue 6): "network" should have a way to indicate what RX and TX mean
(is current way enough? maybe identify endpoints by ID or 4-tuple etc.)

TODO: maybe mention what tools should do with "unknown"?

### Title and Description

Both fields' values are generic strings, used for describing the contents of the
trace. These can either be filled in automatically (e.g., showing the endpoint
name and readable timestamp of the log), or can be filled manually when creating
aggregated logs (e.g., qlog files that illustrate a specific problem across traces
that want to include additional explanations for easier communication between
teams, students, ...).

### Configuration

We take into account that a log file is usually not used in isolation, but by
means of various tools. Especially when aggregating various traces together or
preparing traces for a demonstration, one might wish to persist certain tool-based
settings inside the log file itself. For this, the configuration field is used.

The configuration field can be viewed as a generic metadata field that tools can
fill with their own fields, based on per-tool logic. It is best practice for tools
to prefix each added field with their tool name to prevent collisions across
tools. This document only defines three standard, tool-independent configuration
settings: "time_offset", "time_units" and "original_uris".

#### time_offset
time_offset indicates by how many units of time (see next section) the starting
time of the current trace should be offset. This is useful when comparing logs
taken from various systems, where clocks might not be perfectly synchronous. Users
could use manual tools or automated logic to align traces in time and the found
optimal offsets can be stored in this field for future usage.

#### time_units
Since timestamps and other time-related values can be stored in various
granularities, this field allows to indicate whether storage happens in either
milliseconds ("ms") or microseconds ("us"). If this field is not present, the
default value is "ms". This configuration setting applies to all other timestamps
and time-related values in the trace file and its consituent events as well, not
just the "time_offset" field.

#### original_uris
This is an optional parameter used when merging multiple individual qlog files or
other source files (e.g., when converting .pcaps to qlog). It allows to keep
better track where certain data came from. It is a simple array of strings.


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
events, and SHOULD be part of "event_fields".

Examples comparing traditional JSON vs the qlog format can be found in
{{traditional_json}} and {{qlog_json}}. The events described in these examples are
purely for illustration. Actual event type definitions for the QUIC and HTTP/3
protocols can be found in TODO.

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
"common_fields" and "event_fields" MUST be disregarded by the user (i.e., the
presence of an uknown field is explicitly NOT an error).

This approach makes line-per-line logging easier and faster, as each log statement
only needs to include the data for the events, not the field names. Events can
also be logged and processed separately, as part of a contiguous event-stream.

#### common_fields format

An object containing pairs of "field name"-"field value". Fields included in
"common_fields" indicate that these field values are the same for each event in
the "events" array (with the exception of the "group_ids" field, see {{group_ids}})

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

Only a time-based field (see {{time-based-fields}}), the event field and the data
field are mandatory. Typical setups will log reference_time, protocol_type and
group_id in "common_fields" and relative_time, category, event and data in
"event_fields".

Other field names are allowed, both in "common_fields" and "event_fields", but
their semantics depend on the context of the log usage (e.g., for QUIC, the ODCID
field is used).


### time, delta_time and reference_time + relative_time {#time-based-fields}

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

Events in each individual trace MUST be logged in strictly ascending timestamp
order. Tools are not expected to sort all events on the timestamp before
processing them.

### group_id and group_ids {#group_ids}

A single Trace can contain events from a variety of sources, belonging to for
example a number of individual QUIC connections. For tooling considerations, it is
necessary to have a well-defined way to split up events belonging to different
logical groups into subgroups for visualization and processing. For example, if
one type of log uses 4-tuples as identifiers and uses a field name "four_tuple"
and another uses "ODCID", there is no way to know for generic tools which of these
fields should be used to create subgroups. As such, qlog uses the generic
"group_id" field to circumvent this issue.

The "group_id" field can be any type of valid JSON object, but is typically a
string or integer. For more complex use cases, the group_id could become a complex
object with several fields (e.g., a 4-tuple). In those cases, it would be wasteful
to log these values in full every single time. This would also complicate
tool-based processing. As a solution, qlog allows the extraction of group_id
values into a separate "group_ids" field in the "common_fields", consisting of an
array of the various present group ids for this trace. If this field is present,
per-event "group_id" values are regarded as indices into the "group_ids" array.
This is useful if the group_ids are known up-front or the qlog trace can be
generated from a more verbose format afterwards. If this is not the case, it is
acceptable to just log the complex objects as the "group_id" for each event. Both
use cases are demonstrated in {{group_id_repeated}} and {{group_id_indexed}}.

Since "group_id" and "group_ids" are generic names, they convey little of the
semantics to the casual reader. It is best practice to also include a per use case
additional field to the "common_fields" with a semantic name, that has the same
value as the "group_id" or "group_ids" field. For example, see the "ODCID" field
in {{qlog_json}} and the "four_tuples" field in {{group_id_indexed}}.

TODO: maybe just make group_ids or group_id reference the named field instead?
e.g., "group_id": "ODCID"

TODO: for the simple use case (e.g., just 1 QUIC connection in the trace), MUST a
trace include a group_id? maybe yes: the ODCID? (ODCID because the normal
connection IDs can change during the QUIC connection).

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
            { "ip1": "2001:67c:1232:144:9498:6df6:f450:110b", "ip2": "2001:67c:2b0:1c1::198", "port1": 59105, "port2": 80 }
            "transport",
            "packet_received",
            [...]
        ],[
            1553986553588,
            { "ip1": "10.0.6.137", "ip2": "52.58.13.57", "port1": 56522, "port2": 443 }
            "http",
            "frame_parsed",
            [...]
        ],[
            1553986553598,
            { "ip1": "2001:67c:1232:144:9498:6df6:f450:110b", "ip2": "2001:67c:2b0:1c1::198", "port1": 59105, "port2": 80 }
            "transport",
            "packet_sent",
            [...]
        ],
        ...
    ]
}
~~~~~~~~
{: .language-json}
{: #group_id_repeated title="Repeated complex group id"}


~~~~~~~~
{
    "common_fields": {
        "protocol_type":  "QUIC_HTTP3",
        "group_ids": [
            { "ip1": "2001:67c:1232:144:9498:6df6:f450:110b", "ip2": "2001:67c:2b0:1c1::198", "port1": 59105, "port2": 80 },
            { "ip1": "10.0.6.137", "ip2": "52.58.13.57", "port1": 56522, "port2": 443 }
        ],
        "four_tuples": [
            { "ip1": "2001:67c:1232:144:9498:6df6:f450:110b", "ip2": "2001:67c:2b0:1c1::198", "port1": 59105, "port2": 80 },
            { "ip1": "10.0.6.137", "ip2": "52.58.13.57", "port1": 56522, "port2": 443 }
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
{: #group_id_indexed title="Indexed complex group id"}


### category and event

Both category and event are separate, generic strings. Category allows a
higher-level grouping of events per event type.

For example, instead of having an event of value "transport_packet_sent", we
instead have a category of "transport" and event type of "packet_sent". This
allows for fast and high-level filtering based on category and re-use of event
across categories.

### data

The data field is a generic object (list of name-value pairs). It contains the
per-event metadata and its form and semantics are defined per specific sort of
event (typically per event, but possibly also by combination of category and
event).


### Event field values

The specific values for each of these fields and their semantics are defined in
separate documents, specific per protocol or use case.

For example: event definitions for QUIC and HTTP/3 can be found in
draft-marx-qlog-event-definitions-quic-h3-latest.

## triggers

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
next to each event definition. Triggers can be of any type, but are typically
logged as strings. For an example, see {{trigger_example}}.

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
            20,
            "transport",
            "packet_received",
            [
                // Indicates that the packet wasn't received exactly now,
                // but instead had been buffered because there were no
                // appropriate TLS keys available to decrypt it before.
                "trigger": "keys_available",
                ...
            ]
        ],[
            27,
            "http",
            "frame_created",
            [
                // Indicates that this frame is being created in response
                // to an HTTP GET/POST/... request
                "trigger": "request",
                ...
            ]
        ],
        ...
    ]
}
~~~~~~~~
{: .language-json}
{: #trigger_example title="Trigger example"}

Note: previously, triggers were also top-level fields, similar to category, event
and data itself. However, since many events don't have specific triggers and some
triggers are difficult to implement or keep track of in an implementation flow, it
was decided to make "trigger" an optional property of the data field value
instead.

# Tooling requirements

Tools MUST indicate which qlog version(s) they support. Additionally, they SHOULD
indicate exactly which values for and properties of the category, event and data
fields they look for to execute their logic. Tools SHOULD perform a (high-level)
check if an input qlog file adheres to the expected qlog schema. If a tool
determines a qlog file does not contain enough supported information to correctly
execute the tool's logic, it SHOULD generate a clear error message to this effect.

Tools MUST not produce errors for any field names and values in the qlog format
that they do not recognize. Tools CAN indicate unknown event occurences within
their context (e.g., marking unknown events on a timeline for manual
interpretation by the user).

# Methods of Access

TBD : propose to use a .well-known URL to fetch logs from an endpoint / to send
logs to.

# Notes on Practical Use

TBD : discuss that implementations do not have to output qlog directly. It is good
practice to log in whatever way you want, and then just write a transformer to
qlog for use in tooling.



# Security Considerations

TBD : discuss privacy and security considerations (e.g., what NOT to log, what to
strip out of a log before sharing, ...)

# IANA Considerations

TBD

--- back

# Change Log

## Since draft-marx-qlog-main-schema-00:

* All field names are now lowercase (e.g., category instead of CATEGORY)
* Triggers are now properties on the "data" field value, instead of separate field
  types (#23)

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

