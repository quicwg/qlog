---
title: QUIC and HTTP/3 event definitions for qlog
docname: draft-marx-qlog-event-definitions-quic-h3-latest
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
  QUIC-TRANSPORT:
    title: "QUIC: A UDP-Based Multiplexed and Secure Transport"
    seriesinfo:
      Internet-Draft: draft-ietf-quic-transport-20
    date: 2019-04-23
    author:
      -
        ins: J. Iyengar
        name: Jana Iyengar
        org: Fastly
        role: editor
      -
        ins: M. Thomson
        name: Martin Thomson
        org: Mozilla
        role: editor
  QUIC-HTTP:
    title: "Hypertext Transfer Protocol Version 3 (HTTP/3)"
    date: 2019-04-23
    seriesinfo:
      Internet-Draft: draft-ietf-quic-http-20
    author:
      -
        ins: M. Bishop
        name: Mike Bishop
        org: Akamai
        role: editor

informative:

--- abstract

This document describes concrete qlog event definitions and their metadata for
QUIC and HTTP/3-related events. These events can then be embedded in the higher
level schema defined in draft-marx-quic-logging-main-schema-latest.

--- middle

# Introduction

Feedback and discussion welcome at https://github.com/quiclog/internet-drafts.
Readers are advised to refer to "editor's draft" at that URL for an up-to-date
version of this document.

## Notational Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC2119].

# Overview

This document describes the values of the qlog "category", "event_type" and "data"
fields and their semantics for the QUIC and HTTP/3 protocols. The definitions
included in this file are assumed to be used in qlog's "trace" containers, where
the trace's "protocol_type" field MUST be set to "QUIC_HTTP3".

This document is based on draft-23 of the QUIC and HTTP/3 I-Ds [QUIC-TRANSPORT]
[QUIC-HTTP].

This document uses the ["TypeScript" language](https://www.typescriptlang.org/) to
describe its schema in. We use TypeScript because it is less verbose than
JSON-schema and almost as expressive. It also makes it easier to include these
definitions directly into a web-based tool. TypeScript type definitions for this
document are available at https://github.com/quiclog/qlog/tree/master/TypeScript.
The main conventions a reader should be aware of are:

* obj? : this object is optional
* type1 &#124; type2 : a union of these two types (object can be either type1 OR
  type2)
* obj&#58;type : this object has this concrete type
* obj&#91;&#93; : this object is an array (which can contain any type of object)
* obj&#58;Array&lt;type&gt; : this object is an array of this type
* number : identifies either an integer, float or double in TypeScript. In this
  document, number always means an integer.
* Unless explicity defined, the value of an enum entry is the string version of
  its name (e.g., initial = "initial")
* Many numerical fields have type "string" instead of "number". This is because
  many JSON implementations only support integers up to 2^53-1 (MAX_INTEGER for
  JavaScript without BigInt support), which is less than QUIC's VLIE types
  (2^62-1). Each field that can potentially have a value larger than 2^53-1 is
  thus a string, where a number would be semantically more correct. Unless
  mentioned otherwise (e.g., for connection IDs), numerical fields that are logged
  as strings (e.g., packet numbers) MUST be logged in decimal (base-10) format.
  TODO: see issue 10

# Importance

Not all the listed events are of equal importance to achieve good debuggability.
As such, each event has an "importance indicator" with one of three values, in
decreasing order of importance and exptected usage:

* Core
* Base
* Extra

The "Core" events are the events that SHOULD be present in all qlog files. These
are mostly tied to basic packet and frame parsing and creation, as well as listing
basic internal metrics. Tool implementers SHOULD expect and add support for these
events, though SHOULD NOT expect all Core events to be present in each qlog trace.

The "Base" events add additional debugging options and CAN be present in qlog
files. Most of these can be implicitly inferred from data in Core events (if those
contain all their properties), but for many it is better to log the events
explicitly as well, making it clearer how the implementation behaves. These events
are for example tied to passing data around in buffers, to how internal state
machines change and help show when decisions are actually made based on received
data. Tool implementers SHOULD at least add support for showing the contents of
these events, if they do not handle them explicitly.

The "Extra" events are considered mostly useful for low-level debugging of the
implementation, rather than the protocol. They allow more fine-grained tracking of
internal behaviour. As such, they CAN be present in qlog files and tool
implementers CAN add support for these, but they are not required to.

Note that in some cases, implementers might not want to log frame-level details in
the "Core" events due to performance considerations. In this case, they SHOULD use
(a subset of) relevant "Base" events instead to ensure usability of the qlog
output. As an example, implementations that do not log "packet_received" events
and thus also not which (if any) ACK frames the packet contain, SHOULD log
packets_acknowledged events instead.

# QUIC event definitions

* TODO: flesh out the definitions for most of these
* TODO: add all definitions for HTTP3 and QPACK events

## connectivity

### server_listening
Importance: Extra

Emitted when the server starts accepting connections.

Data:

~~~
{
    ip_v4?: string,
    ip_v6?: string,
    port: number,

    quic_versions?: Array<string>,
    alpn_values?: Array<string>,

    early_data_allowed?:boolean,
    stateless_reset_required?:boolean
}
~~~

### connection_started
Importance: Base

Used for both attempting (client-perspective) and accepting (server-perspective)
new connections.

Data:

~~~
{
    ip_version: string,
    src_ip: string,
    dst_ip: string,

    protocol?: string, // (default "QUIC")
    src_port: number,
    dst_port: number,

    quic_version?: string,
    src_cid?: string,
    dst_cid?: string
}
~~~

### connection_id_updated
Importance: Core

This is viewed from the perspective of the one applying the new id. As such, if we
receive a new connection id from our peer, we will see the dst_ fields are set. If
we update our own connection id (e.g., NEW_CONNECTION_ID frame), we log the src_
fields.

Data:

~~~
{
    src_old?: string,
    src_new?: string,

    dst_old?: string,
    dst_new?: string
}
~~~

### spin_bit_updated
Importance: Base

TODO: is this best as a connectivity event? should this be in transport/recovery instead?

Data:

~~~
{
    state: boolean
}
~~~

### connection_retried

TODO

### connection_closed
Importance: Extra

Data:

~~~
{
    src_id?: string // (only needed when logging in a trace containing data for multiple connections. Otherwise it's implied.)
}
~~~

Triggers:

* "error"
* "clean"

### MIGRATION-related events
e.g., path_updated

TODO: read up on the draft how migration works and whether to best fit this here or in TRANSPORT
TODO: integrate https://tools.ietf.org/html/draft-deconinck-quic-multipath-02

## security

### cipher_updated
Importance: Base

TODO: assume this will only happen once at the start, but check up on that!
TODO: maybe this is not the ideal name?

Data:

~~~
{
    cipher_type:string  // (e.g., AES_128_GCM_SHA256)
}
~~~

### key_updated
Importance: Base

Note: secret_update would be more correct, but in the draft it's called KEY_UPDATE, so stick with that for consistency

Data:

~~~
{
    key_type:KeyType,
    old?:string,
    new:string,
    generation?:number
}
~~~

Triggers:

* "tls" // (e.g., initial, handshake and 0-RTT keys are generated by TLS)
* "remote_update"
* "local_update"

### key_retired
Importance: Base

Data:

~~~
{
    key_type:KeyType,
    key:string,
    generation?:number
}
~~~

Triggers:

* "tls" // (e.g., initial, handshake and 0-RTT keys are dropped implicitly)
* "remote_update"
* "local_update"

## transport

### datagram_sent
Importance: Extra

When we pass a UDP-level datagram to the socket

Data:

~~~
{
    count?:number, // to support passing multiple at once
    byte_length:number
}
~~~

### datagram_received
Importance: Extra

When we receive a UDP-level datagram from the socket.

Data:

~~~
{
    count?:number, // to support passing multiple at once
    byte_length:number
}
~~~

### packet_sent
Importance: Core

Data:

~~~
{
    packet_type:PacketType,
    header:PacketHeader,
    frames:Array<QuicFrame>, // see appendix for the definitions

    is_coalesced?:boolean,

    raw_encrypted?:string, // for debugging purposes
    raw_decrypted?:string  // for debugging purposes
}
~~~

Note: We do not explicitly log the encryption_level or packet_number_space: the
packet_type specifies this by inference (assuming correct implementation)

Triggers:

* "retransmit_reordered" // draft-23 5.1.1
* "retransmit_timeout" // draft-23 5.1.2
* "pto_probe" // draft-23 5.3.1
* "retransmit_crypto" // draft-19 6.2
* "cc_bandwidth_probe" // needed for some CCs to figure out bandwidth allocations
  when there are no normal sends


### packet_received
Importance: Core

Data:

~~~
{
    packet_type:PacketType,
    header:PacketHeader,
    frames:Array<QuicFrame>;, // see appendix for the definitions

    is_coalesced?:boolean,

    raw_encrypted?:string, // for debugging purposes
    raw_decrypted?:string  // for debugging purposes
}
~~~

Note: We do not explicitly log the encryption_level or packet_number_space: the
packet_type specifies this by inference (assuming correct implementation)

Triggers:

* "keys_available" // if packet was buffered because it couldn't be decrypted
  before

### packet_dropped
Importance: Base

Data:

~~~
{
    packet_size:number,
    raw?:string, // hex encoded
}
~~~

Can be due to several reasons
* TODO: How does this relate to HEADER_DECRYPT ERROR and PAYLOAD_DECRYPT ERROR?
* TODO: if a packet is dropped because we don't have a connection for it, how can
  we add it to a given trace in the overall qlog file? Need a sort of catch-call
  trace in each file?
* TODO: differentiate between DATAGRAM_DROPPED and PACKET_DROPPED? Same with
  PACKET_RECEIVED and DATAGRAM_RECEIVED?


### packet_buffered
Importance: Base

TODO: No need to repeat full packet here, should be logged in another event for that

Data:

~~~
{
    packet_type:PacketType,
    packet_number:string
}
~~~

Triggers:

* "backpressure" // indicates the parser cannot keep up, temporarily buffers
  packet for later processing
* "keys_unavailable" // if packet cannot be decrypted because the proper keys were
  not yet available

### stream_state_updated
Importance: Base

Data:

~~~
{
    old:string,
    new:string
}
~~~

Possible values:

* idle
* open
* closed
* half_closed_remote
* half_closed_local
* destroyed // memory actually freed

* Ready
* Send
* Data Sent
* Reset Sent
* Data Rcvd
* Reset Rcvd

* Recv
* Size Known
* Data Rcvd
* Data Read
* Reset Read

TODO: do we need all of these? How do implementations actually handle this in
practice?

### flow_control_updated
Importance: Base

* type = connection
* type = stream + id = streamid

TODO: check state machine in QUIC transport draft

### version_updated
Importance: Base

TODO: check semantics on this: can versions update? will they ever? change to
version_selected?

Data:

~~~
{
    old:string,
    new:string
}
~~~

### transport_parameters_updated
Importance: Core

Data:

~~~
{
    owner:string = "local" | "remote",
    parameters:Array<TransportParameter>;
}
~~~


### ALPN_updated
Importance: Core

Data:

~~~
{
    old:string,
    new:string
}
~~~

## recovery

### metrics_updated
Importance: Core

Data:

~~~
{
    cwnd?: number,
    bytes_in_flight?:number,

    min_rtt?:number,
    smoothed_rtt?:number,
    latest_rtt?:number,
    max_ack_delay?:number,

    rtt_variance?:number,
    ssthresh?:number,

    pacing_rate?:number,

    maximum_packet_size?:number // e.g., when updated after pmtud
}
~~~

This event SHOULD group all possible metric updates that happen at or around the
same time in a single event (e.g., if min_rtt and smoothed_rtt change at the same
time, they should be bundled in a single METRIC_UPDATE entry, rather than split
out into two). Consequently, a metrics_updated event is only guaranteed to contain
at least one of the listed metrics.

Note: to make logging easier, implementations MAY log values even if they are the
same as previously reported values (e.g., two subsequent METRIC_UPDATE entries can
both report the exact same value for min_rtt). However, applications SHOULD try to
log only actual updates to values.

* TODO: what types of CC metrics do we need to support by default (e.g., cubic vs
  bbr)


### loss_timer_set
Importance: Extra

Data:

~~~
{
    timer_type:"ack"|"pto", // called "mode" in draft-23 A.9.
    timeout:number
}
~~~

### loss_timer_expired
Importance: Extra

Data:

~~~
{
    timer_type:"ack"|"pto", // called "mode" in draft-23 A.9.
}
~~~

### packet_lost
Importance: Core

Data:

~~~
{
    packet_type:PacketType,
    packet_number:string,

    // not all implementations will keep track of full packets, so these are optional
    header?:PacketHeader,
    frames?:Array<QuicFrame>, // see appendix for the definitions
}
~~~

Triggers:

* "reordering_threshold",
* "time_threshold"
* "pto_expired" // draft-23 section 5.3.1, MAY

### packets_acknowledged
Importance: Extra

TODO: must this be a separate event? can't we get this from logged ACK frames?
(however, explicitly indicating this and logging it in the ack handler is a better
signal that the ACK actually had the intended effect than just logging its
receipt)

### packet_retransmitted
Importance: Extra

TODO: only if a packet is retransmit in-full, which many stacks don't do. Need
something more flexible.

# HTTP/3 event definitions

## http

Note: like all category values, the "http" category is written in lowercase.

### stream_state_updated
Importance: Base

Data:

~~~~
{
    id:string,
    old:string,
    new:string
}
~~~~

Possible values:

* open // maybe local_open, remote_open?
* closed // maybe local_closed, remote_closed?
* expecting_push
* expecting_settings
* cancelled

Currently, there is no proper state diagram in the HTTP draft (as opposed to the
quic draft). TODO: figure out proper values for this.

Triggers:

* "request" // opened due to GET,POST,PUT,DELETE,... request from peer
* "push"
* "reset" // closed due to reset from peer


### stream_type_updated
Importance: Base

TODO: possible merge this with stream_state_update? Don't really want to watch for
2 events to get a newly opened stream + know what type it is

Data:

~~~~
{
    id:string,
    old:string,
    new:string,
    owner:"local"|"remote"
}
~~~~
Possible values:

* data
* control
* qpack_encode
* qpack_decode
* push
* reserved

Currently, there is no proper state diagram in the HTTP draft (as opposed to the
quic draft). TODO: figure out proper values for this.


### frame_created
Importance: Core

HTTP equivalent to the packet_sent event. This event is emitted when the HTTP/3
framing actually happens. Note: this is not necessarily the same as when the
HTTP/3 data is passed on to the QUIC layer. For that, see the "data_moved" event.

Data:

~~~
{
    stream_id:string,
    frame:HTTP3Frame // see appendix for the definitions,
    byte_length:string,

    raw?:string
}
~~~

### frame_parsed
Importance: Core

HTTP equivalent to the packet_received event. This event is emitted when we
actually parse the HTTP/3 frame. Note: this is not necessarily the same as when
the HTTP/3 data is actually received on the QUIC layer. For that, see the
"data_moved" event.

TODO: how do we deal with partial frames (e.g., length is very long, we're
streaming this incrementally: events should indicate this setup? or you just have
1 frame_parsed and several data_received events for that stream?). Similar for
frame_created.

Data:

~~~
{
    stream_id:string,
    frame:HTTP3Frame // see appendix for the definitions,
    byte_length:string,

    raw?:string
}
~~~

### data_moved
Importance: Extra

Used to indicate when data moves between the HTTP/3 and the transport layer (e.g.,
passing from H3 to QUIC stream buffers and vice versa) or between HTTP/3 and the
actual user application on top (e.g., a browser engine). This helps debug errors
where buffers are full with ready data, but aren't beind drained fast enough.

Data:

~~~~
{
    stream_id:string,
    offset_start?:string,
    offset_end?:string,

    length?:number, // to be used mainly if no exact offsets are known

    from?:"application"|"transport",
    to?:"application"|"transport"
}
~~~~

The "from" and "to" fields MUST NOT be set at the same time. The missing field is
always implied to have the value "http".

TODO: add separate event to highlight when we didn't receive enough data to
actually decode an H3 frame (e.g., only received 1 byte of 2-byte VLIE encoded
value)

TODO: add separate diagnostic event(s) to indicate when HOL-blocking occured (both
inter-stream in H3 and intra-stream in QPACK layers and for control stream packets
(e.g., prioritization, push))

## QPACK

### header_encoded
Importance: Base

Data:

~~~~
{
    stream_id?:string, // not necessarily available at the QPACK level

    encoded:string,
    fields:Array<HTTPHeader>
}
~~~~

### header_decoded
Importance: Base

Data:

~~~~
{
    stream_id?:string, // not necessarily available at the QPACK level

    encoded:string,
    fields:Array<HTTPHeader>
}
~~~~

### TODO

Add more qpack-specific events
For example:
* Encoder Instruction
* Decoder Instruction


## prioritization

TODO: add some higher-level primitives that can work regardless of the resulting
scheme and then add some more specific things later? e.g., scheduler_updated?


## PUSH

TODO

# General error and warning definitions

## error

### header_decrypt
Importance: Base

Data:

~~~~
{
    mask:string, // hex-formatted
    error:string
}
~~~~

### payload_decrypt
Importance: Base

Data:

~~~~
{
    key:string, // hex-formatted
    error:string
}
~~~~

### connection_error
Importance: Extra

Data:

~~~~
{
    code?:TransportError | number,
    description:string
}
~~~~

### application_error
Importance: Extra

Data:

~~~~
{
    code?:ApplicationError | number,
    description:string
}
~~~~

### internal_error
Importance: Base

Data:

~~~~
{
    code?:number,
    description:string
}
~~~~

## warning

### internal_warning
Importance: Base

Data:

~~~~
{
    code?:number,
    description:string
}
~~~~

## info

### message
Importance: Extra

Data:

~~~~
{
    message:string
}
~~~~

## debug

### message
Importance: Extra

Data:

~~~~
{
    message:string
}
~~~~

## verbose

### message
Importance: Extra

Data:

~~~~
{
    message:string
}
~~~~


# Security Considerations

TBD

# IANA Considerations

TBD

--- back

# QUIC DATA type definitions

## TransportParameter

~~~
class TransportParameter
{
    name:string, // TODO: list all transport parameters properly in an enum
    raw_name:string, // for unknown parameters
    content:any
}
~~~

## PacketType

~~~
enum PacketType {
    initial,
    handshake,
    zerortt = "0RTT",
    onertt = "1RTT",
    retry,
    version_negotiation,
    unknown
}
~~~

## PacketHeader

~~~
class PacketHeader {
    packet_number: string;
    packet_size?: number;
    payload_length?: number;

    // only if present in the header
    // if correctly using NEW_CONNECTION_ID events,
    // dcid can be skipped for 1RTT packets
    version?: string;
    scil?: string;
    dcil?: string;
    scid?: string;
    dcid?: string;

    // Note: short vs long header is implicit through PacketType
}
~~~

## KeyType
~~~
enum KeyType {
    server_initial_secret,
    client_initial_secret,

    server_handshake_secret,
    client_handshake_secret,

    server_0rtt_secret,
    client_0rtt_secret,

    server_1rtt_secret,
    client_1rtt_secret
}
~~~

## QUIC Frames

~~~
type QuicFrame = PaddingFrame | PingFrame | AckFrame | ResetStreamFrame | StopSendingFrame | CryptoFrame | NewTokenFrame | StreamFrame | MaxDataFrame | MaxStreamDataFrame | MaxStreamsFrame | DataBlockedFrame | StreamDataBlockedFrame | StreamsBlockedFrame | NewConnectionIDFrame | RetireConnectionIDFrame | PathChallengeFrame | PathResponseFrame | ConnectionCloseFrame | UnknownFrame;
~~~

### PaddingFrame

~~~
class PaddingFrame{
    frame_type:string = "padding";
}
~~~

### PingFrame

~~~
class PingFrame{
    frame_type:string = "ping";
}
~~~

### AckFrame

~~~
class AckFrame{
    frame_type:string = "ack";

    ack_delay:string;

    // first number is "from": lowest packet number in interval
    // second number is "to": up to and including // highest packet number in interval
    // e.g., looks like [["1","2"],["4","5"]]
    acked_ranges:Array<[string, string]>;

    ect1?:string;
    ect0?:string;
    ce?:string;
}
~~~

Note: the packet ranges in AckFrame.acked_ranges do not necessarily have to be
ordered (e.g., \[\["5","9"\],\["1","4"\]\] is a valid value).

Note: the two numbers in the packet range can be the same (e.g., \[120,120\] means
that packet with number 120 was ACKed). TODO: maybe make this into just \[120\]?

### ResetStreamFrame
~~~
class ResetStreamFrame{
    frame_type:string = "reset_stream";

    id:string;
    error_code:ApplicationError | number;
    final_size:string;
}
~~~


### StopSendingFrame
~~~
class StopSendingFrame{
    frame_type:string = "stop_sending";

    id:string;
    error_code:ApplicationError | number;
}
~~~

### CryptoFrame

~~~
class CryptoFrame{
  frame_type:string = "crypto";

  offset:string;
  length:string;
}
~~~

### NewTokenFrame

~~~
class NewTokenFrame{
  frame_type:string = "new_token";

  length:string;
  token:string;
}
~~~


### StreamFrame

~~~
class StreamFrame{
    frame_type:string = "stream";

    id:string;

    // These two MUST always be set
    // If not present in the Frame type, log their default values
    offset:string;
    length:string;

    // this MAY be set any time, but MUST only be set if the value is "true"
    // if absent, the value MUST be assumed to be "false"
    fin:boolean;

    raw?:string;
}
~~~

### MaxDataFrame

~~~
class MaxDataFrame{
  frame_type:string = "max_data";

  maximum:string;
}
~~~

### MaxStreamDataFrame

~~~
class MaxStreamDataFrame{
  frame_type:string = "max_stream_data";

  id:string;
  maximum:string;
}
~~~

### MaxStreamsFrame

~~~
class MaxStreamsFrame{
  frame_type:string = "max_streams";

  stream_type:string = "bidirectional" | "unidirectional";
  maximum:string;
}
~~~

### DataBlockedFrame

~~~
class DataBlockedFrame{
  frame_type:string = "data_blocked";

  limit:string;
}
~~~

### StreamDataBlockedFrame

~~~
class StreamDataBlockedFrame{
  frame_type:string = "stream_data_blocked";

  id:string;
  limit:string;
}
~~~

### StreamsBlockedFrame

~~~
class StreamsBlockedFrame{
  frame_type:string = "streams_blocked";

  stream_type:string = "bidirectional" | "unidirectional";
  limit:string;
}
~~~


### NewConnectionIDFrame

~~~
class NewConnectionIDFrame{
  frame_type:string = "new_connection_id";

  sequence_number:string;
  retire_prior_to:string;

  length:number;
  connection_id:string;

  reset_token:string;
}
~~~

### RetireConnectionIDFrame

~~~
class RetireConnectionIDFrame{
  frame_type:string = "retire_connection_id";

  sequence_number:string;
}
~~~

### PathChallengeFrame

~~~
class PathChallengeFrame{
  frame_type:string = "path_challenge";

  data?:string;
}
~~~

### PathResponseFrame

~~~
class PathResponseFrame{
  frame_type:string = "patch_response";

  data?:string;
}
~~~

### ConnectionCloseFrame

raw_error_code is the actual, numerical code. This is useful because some error
types are spread out over a range of codes (e.g., QUIC's crypto_error).

~~~

type ErrorSpace = "transport" | "application";

class ConnectionCloseFrame{
    frame_type:string = "connection_close";

    error_space:ErrorSpace;
    error_code:TransportError | ApplicationError | number;
    raw_error_code:number;
    reason:string;

    trigger_frame_type?:number; // TODO: should be more defined, but we don't have a FrameType enum atm...
}
~~~

### UnknownFrame

~~~
class UnknownFrame{
    frame_type:string = "unknown";
    raw_frame_type:number;
}
~~~

### TransportError
~~~
enum TransportError {
    no_error,
    internal_error,
    server_busy,
    flow_control_error,
    stream_limit_error,
    stream_state_error,
    final_size_error,
    frame_encoding_error,
    transport_parameter_error,
    protocol_violation,
    invalid_migration,
    crypto_buffer_exceeded,
    crypto_error
}
~~~


# HTTP/3 DATA type definitions

## HTTP/3 Frames

~~~
type HTTP3Frame = DataFrame | HeadersFrame | PriorityFrame | CancelPushFrame | SettingsFrame | PushPromiseFrame | GoAwayFrame | MaxPushIDFrame | DuplicatePushFrame | ReservedFrame | UnknownFrame;
~~~

### DataFrame
~~~
class DataFrame{
    frame_type:string = "data"
}
~~~

### HeadersFrame

This represents an *uncompressed*, plaintext HTTP Headers frame (e.g., no QPACK
compression is applied).

For example:

~~~
fields: [{"name":":path","content":"/"},{"name":":method","content":"GET"},{"name":":authority","content":"127.0.0.1:4433"},{"name":":scheme","content":"https"}]
~~~

TODO: use proper HTTP naming for the fields, names, values, etc.

~~~
class HeadersFrame{
    frame_type:string = "header",
    fields:Array<HTTPHeader>
}

class HTTPHeader {
    name:string,
    content:string
}
~~~

### PriorityFrame

~~~
class PriorityFrame{
    frame_type:string = "priority",

    prioritized_element_type:string = "request_stream"  | "push_stream" | "placeholder" | "root",
    element_dependency_type?:string = "stream_id"       | "push_id"     | "placeholder_id",

    exclusive:boolean,

    prioritized_element_id:string,
    element_dependency_id:string,
    weight:number

}
~~~

### CancelPushFrame
~~~
class CancelPushFrame{
    frame_type:string = "cancel_push",
    id:string
}
~~~

### SettingsFrame
~~~
class SettingsFrame{
    frame_type:string = "settings",
    fields:Array<Setting>
}

class Setting{
    name:string = "SETTINGS_MAX_HEADER_LIST_SIZE" | "SETTINGS_NUM_PLACEHOLDERS",
    content:string
}
~~~

### PushPromiseFrame

~~~
class PushPromiseFrame{
    frame_type:string = "push_promise",
    id:string,

    fields:Array<HTTPHeader>
}
~~~

### GoAwayFrame
~~~
class GoAwayFrame{
    frame_type:string = "goaway",
    id:string
}
~~~

### MaxPushIDFrame
~~~
class MaxPushIDFrame{
    frame_type:string = "max_push_id",
    id:string
}
~~~

### DuplicatePushFrame
~~~
class DuplicatePushFrame{
    frame_type:string = "duplicate_push",
    id:string
}
~~~

### ReservedFrame
~~~
class ReservedFrame{
    frame_type:string = "reserved"
}
~~~

### UnknownFrame

HTTP/3 re-uses QUIC's UnknownFrame definition, since their values and usage
overlaps.


## ApplicationError
~~~
enum ApplicationError{
    http_no_error,
    http_general_protocol_error,
    reserved,
    http_internal_error,
    http_request_cancelled,
    http_incomplete_request,
    http_connect_error,
    http_excessive_load,
    http_version_fallback,
    http_wrong_stream,
    http_id_error,
    http_stream_creation_error,
    http_closed_critical_stream,
    http_early_response,
    http_missing_settings,
    http_unexpected_frame,
    http_request_rejected,
    http_settings_error,
    http_malformed_frame
}
~~~

TODO: http_malformed_frame is not a single value, but can include the frame type
in its definition. This means we need more flexible error logging. Best to wait
until h3-draft-23 (PR https://github.com/quicwg/base-drafts/pull/2662), which will
include substantial changes to error codes.

# Change Log

## Since draft-00:

- Added many new events and their definitions
- Events are given an importance indicator (issue \#22)
- Event names are more consistent and use past tense (issue \#21)

# Design Variations

TBD

# Acknowledgements

Thanks to Jana Iyengar, Brian Trammell, Dmitri Tikhonov, Stephen Petrides, Jari
Arkko, Marcus Ihlar, Victor Vasiliev, Mirja Kühlewind, Jeremy Lainé and Lucas
Pardue for their feedback and suggestions.

