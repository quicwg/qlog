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

Feedback and discussion welcome at https://github.com/quiclog/internet-drafts

## Notational Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC2119].

# Overview

This document describes the values of the qlog CATEGORY, EVENT_TYPE, TRIGGER and
DATA fields and their semantics for the QUIC and HTTP/3 protocols. The definitions
included in this file are assumed to be used in qlog's "trace" containers, where
the trace's "protocol_type" field MUST be set to "QUIC_HTTP3".

This document is based on draft-20 of the QUIC and HTTP/3 I-Ds [QUIC-TRANSPORT]
[QUIC-HTTP].

This document uses the ["TypeScript" language](https://www.typescriptlang.org/) to
describe its schema in. We use TypeScript because it is less verbose than
JSON-schema and almost as expressive. It also makes it easier to include these
definitions directly into a web-based tool. The main conventions a reader should
be aware of are:

* obj? : this object is optional
* type1 &#124; type2 : a union of these two types (object can be either type1 OR
  type2)
* obj&#58;type : this object has this concrete type
* obj&#91;&#93; : this object is an array (which can contain any type of object)
* obj&#58;Array&lt;type&gt; : this object is an array of this type
* number : identifies either an integer, float or double in TypeScript. In this
  document, number always means an integer.
* Unless explicity defined, the value of an enum entry is the string version of
  its name (e.g., INITIAL = "INITIAL")
* Many numerical fields have type "string" instead of "number". This is because
  many JSON implementations only support integers up to 2^53-1 (MAX_INTEGER for
  JavaScript without BigInt support), which is less than QUIC's VLIE types
  (2^62-1). Each field that can potentially have a value larger than 2^53-1 is
  thus a string, where a number would be semantically more correct. Unless
  mentioned otherwise (e.g., for connection IDs), numerical fields that are logged
  as strings (e.g., packet numbers) MUST be logged in decimal (base-10) format.
  TODO: see issue 10

* TODO: list all possible triggers per event type
* TODO: make it clear which events are "normal" and which are "only if you really
need this" (normal = probably TRANSPORT TX/RX and RECOVERY basics and HTTP basics)

# QUIC event definitions

* TODO: flesh out the definitions for most of these
* TODO: add all definitions for HTTP3 and QPACK events

## connectivity

### listening
~~~
{
    ip: string,
    port: number,

    quic_versions?: Array<string>,
    alpn_values?: Array<string>
}
~~~

### connection_new
Used for both attempting (client-perspective) and accepting (server-perspective)
new connections.

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

### connection_id_update
This is viewed from the perspective of the one applying the new id. As such, if we
receive a new connection id from our peer, we will see the dst_ fields are set. If
we update our own connection id (e.g., NEW_CONNECTION_ID frame), we log the src_
fields.

~~~
{
    src_old?: string,
    src_new?: string,

    dst_old?: string,
    dst_new?: string
}
~~~

### spin_bit_update
TODO: is this best as a connectivity event? should this be in transport/recovery instead?

~~~
{
    state: boolean
}
~~~

### connection_retry

TODO

### connection_close

~~~
{
    src_id?: string (only needed when logging in a trace containing data for multiple connections. Otherwise it's implied.)
}
~~~

Triggers:
* "error"
* "clean"

### MIGRATION-related events
e.g., path_update

TODO: read up on the draft how migration works and whether to best fit this here or in TRANSPORT
TODO: integrate https://tools.ietf.org/html/draft-deconinck-quic-multipath-02

## security

### cipher_update

TODO: assume this will only happen once at the start, but check up on that!
TODO: maybe this is not the ideal name?

~~~
{
    type:string  // (e.g., AES_128_GCM_SHA256)
}
~~~

### key_update

Note: secret_update would be more correct, but in the draft it's called KEY_UPDATE, so stick with that for consistency

~~~
{
    type:KeyType,
    old?:string,
    new:string,
    generation?:number
}
~~~

Triggers:
* "tls" (TLS gives us new secret)
* "remote_update"
* "local_update"

### key_retire
~~~
{
    type:KeyType,
    key:string,
    generation?:number
}
~~~

Triggers:
* "implicit" // (e.g., initial, handshake and 0-RTT keys are dropped implicitly)
* "remote_update"
* "local_update"

## transport

### datagram_sent
When we pass a UDP-level datagram to the socket

~~~
{
    count:number, // to support passing multiple at once
    byte_length:number
}
~~~

### datagram_received
When we receive a UDP-level datagram from the socket.

~~~
{
    count:number, // to support passing multiple at once
    byte_length:number
}
~~~

### packet_sent

Triggers:

* "DEFAULT"
* "RETRANSMIT_REORDERING" // draft-19 6.1.1
* "RETRANSMIT_TIMEOUT" // draft-19 6.1.2
* "RETRANSMIT_CRYPTO" // draft-19 6.2
* "RETRANSMIT_PTO" // draft-19 6.3
* "CC_BANDWIDTH_PROBE" // needed for some CCs to figure out bandwidth allocations
  when there are no normal sends

Data:

~~~
{
    type:PacketType,
    header:PacketHeader,
    frames:Array<QuicFrame>, // see appendix for the definitions

    raw_encrypted?:string, // for debugging purposes
    raw_decrypted?:string  // for debugging purposes
}
~~~

Notes:

* We don't explicitly log the encryption_level or packet_number_space: the
  packet_type specifies this by inference (assuming correct implementation)

### packet_received

Triggers:

* "DEFAULT"

Data:

~~~
{
    type:PacketType,
    header:PacketHeader,
    frames:Array<QuicFrame>, // see appendix for the definitions

    raw_encrypted?:string, // for debugging purposes
    raw_decrypted?:string  // for debugging purposes
}
~~~

Notes:

* We don't explicitly log the encryption_level or packet_number_space: the
  packet_type specifies this by inference (assuming correct implementation)

### packet_dropped

Can be due to several reasons
* TODO: How does this relate to HEADER_DECRYPT ERROR and PAYLOAD_DECRYPT ERROR?
* TODO: if a packet is dropped because we don't have a connection for it, how can
  we add it to a given trace in the overall qlog file? Need a sort of catch-call
  trace in each file?
* TODO: differentiate between DATAGRAM_DROPPED and PACKET_DROPPED? Same with
  PACKET_RECEIVED and DATAGRAM_RECEIVED?


### packet_buffered
No need to repeat full packet here, should be logged in another event for that

~~~
{
    type:PacketType,
    packet_number:string
}
~~~

Triggers:

* "keys_unavailable"

### stream_state_update

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

### flow_control_update
* type = connection
* type = stream + id = streamid

TODO: check state machine in QUIC transport draft

### version_update
TODO: check semantics on this: can versions update? will they ever? change to
version_selected?

~~~
{
    old:string,
    new:string
}
~~~

### transport_parameters_update

~~~
{
    owner:string = "local" | "remote",
    parameters:Array<TransportParameter>
}
~~~


### ALPN_update

~~~
{
    old:string,
    new:string
}
~~~

## recovery

### state_update

~~~
{
    old:string,
    new:string
}
~~~

### metric_update
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
}
~~~

This event SHOULD group all possible metric updates that happen at or around the
same time in a single event (e.g., if min_rtt and smoothed_rtt change at the same
time, they should be bundled in a single METRIC_UPDATE entry, rather than split
out into two). Consequently, a METRIC_UPDATE is only guaranteed to contain at
least one of the listed metrics.

Note: to make logging easier, implementations MAY log values even if they are the
same as previously reported values (e.g., two subsequent METRIC_UPDATE entries can
both report the exact same value for min_rtt). However, applications SHOULD try to
log only actual updates to values.

* TODO: split these up into separate events? e.g., CWND_UPDATE,
  BYTES_IN_FLIGHT_UPDATE, ...
* TODO: move things like pacing_rate, cwnd, bytes_in_flight, ssthresh, etc. to
  CC_STATE_UPDATE?
* TODO: what types of CC metrics do we need to support by default (e.g., cubic vs
  bbr)


### loss_alarm_set

### loss_alarm_triggered

### packet_lost

Data:

~~~
{
    type:PacketType,
    packet_number:string,

    // not all implementations will keep track of full packets, so these are optional
    header?:PacketHeader,
    frames?:Array<QuicFrame>, // see appendix for the definitions
}
~~~

Triggers:

* "UNKNOWN",
* "REORDERING_THRESHOLD",
* "TIME_THRESHOLD"

### packet_acknowledged

TODO: must this be a separate event? can't we get this from logged ACK frames?
(however, explicitly indicating this and logging it in the ack handler is a better
signal that the ACK actually had the intended effect than just logging its
receipt)

### packet_retransmit

TODO: only if a packet is retransmit in-full, which many stacks don't do. Need
something more flexible.

# HTTP/3 event definitions

## HTTP

### stream_state_update

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
* default
* request // opened due to GET,POST,PUT,DELETE,... request from peer
* push


### stream_type_update

TODO: possible merge this with stream_state_update? Don't really want to watch for
2 events to get a newly opened stream + know what type it is

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
HTTP equivalent to packet_sent

~~~
{
    stream_id:string,
    frame:HTTP3Frame // see appendix for the definitions,
    byte_length:string,

    raw?:string
}
~~~

### frame_parsed
HTTP equivalent to packet_received

TODO: how do we deal with partial frames (e.g., length is very long, we're
streaming this incrementally: events should indicate this setup? or you just have
1 frame_parsed and several data_received events for that stream?). Similar for
frame_created.

~~~
{
    stream_id:string,
    frame:HTTP3Frame // see appendix for the definitions,
    byte_length:string,

    raw?:string
}
~~~

### data_moved

Used to indicate when data moves from the HTTP/3 to the transport layer (e.g.,
passing from H3 to QUIC stream buffers). This is not always the same as frame
creation.

~~~~
{
    stream_id:string,
    offset_start:string,
    offset_end:string

    recipient:"application"|"transport"
}
~~~~

### data_received

Used to indicate when data moves from the transport to the HTTP/3 layer (e.g.,
passing from QUIC to H3 stream buffers).

TODO: should this be a Transport:data_moved event instead? now it's contained in
H3, but maybe we should split this?

TODO: merge this with data_moved and add more general "direction" field? However,
having separate events also makes a lot of sense for easy high-level filtering
without having to look at .recipient or .source

~~~~
{
    stream_id:string,
    offset_start:string,
    offset_end:string,

    source:"application"|"transport"
}
~~~~

TODO: add separate event to highlight when we didn't receive enough data to
actually decode an H3 frame (e.g., only received 1 byte of 2-byte VLIE encoded
value)

TODO: add separate diagnostic event(s) to indicate when HOL-blocking occured (both
inter-stream in H3 and intra-stream in QPACK layers and for control stream packets
(e.g., prioritization, push))

## QPACK

### header_encoded
~~~~
{
    stream_id?:string, // not necessarily available at the QPACK level

    encoded:string,
    fields:Array<HTTPHeader>
}
~~~~

### header_decoded
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

### dependency_update
~~~~
{
    stream_id:string,
    type:string = "added" | "moved" | "removed",

    parent_id_old?:string,
    parent_id_new?:string,

    weight_old?:number,
    weight_new?:number
}
~~~~


## PUSH

TODO

# General error and warning definitions

## ERROR

### HEADER_DECRYPT
~~~~
{ mask, error }
~~~~

### PAYLOAD_DECRYPT
~~~~
{ key, error }
~~~~

### CONNECTION_ERROR
~~~~
{
    code?:TransportError | number,
    description:string
}
~~~~

### APPLICATION_ERROR
~~~~
{
    code?:ApplicationError | number,
    description:string
}
~~~~

### INTERNAL_ERROR
~~~~
{
    code?:number,
    description:string
}
~~~~

## WARNING

### INTERNAL_WARNING
~~~~
{
    code?:number,
    description:string
}
~~~~

## INFO

### MESSAGE
~~~~
{
    message:string
}
~~~~

## DEBUG

### MESSAGE
~~~~
{
    message:string
}
~~~~

## VERBOSE

### MESSAGE
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
    version_negotation,
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

## Since draft-marx-qlog-event-definitions-quic-h3-latest-00:

- None yet.

# Design Variations

TBD

# Acknowledgements

Thanks to Jana Iyengar, Brian Trammell, Dmitri Tikhonov, Stephen Petrides, Jari
Arkko, Marcus Ihlar, Victor Vasiliev, Mirja Kühlewind and Lucas Pardue for their
feedback and suggestions.

