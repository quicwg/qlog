---
title: QUIC and HTTP/3 event definitions for qlog
docname: draft-marx-quic-logging-event-definitions-latest
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
      Internet-Draft: draft-ietf-quic-transport-19
    date: 2018-10-23
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

informative:
  RFC7838:
  QUIC-HTTP:
    title: "Hypertext Transfer Protocol Version 3 (HTTP/3)"
    date: 2018-10-23
    seriesinfo:
      Internet-Draft: draft-ietf-quic-http-19
    author:
      -
        ins: M. Bishop
        name: Mike Bishop
        org: Akamai
        role: editor

--- abstract

This document describes concrete qlog event definitions and their metadata for
QUIC and HTTP/3-related events. These events can then be embedded in the higher
level schema defined in draft-marx-quic-logging-main-schema-latest.

--- middle

# Introduction

TODO

## Notational Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC2119].

# Overview

This document describes the values of the qlog CATEGORY, EVENT_TYPE, TRIGGER and
DATA fields and their semantics for the QUIC and HTTP/3 protocols. The definitions
included in this file are assumed to be used in qlog's "trace" containers, where
the trace's "protocol_type" field MUST be set to "QUIC_HTTP3".

This document is based on draft-19 of the QUIC and HTTP/3 I-Ds. TODO: add ref

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
  (2^62-1). Each VLIE field is thus a string, where a number would be semantically
  more correct. Unless mentioned otherwise (e.g., for connection IDs), numerical
  fields that are logged as strings (e.g., packet numbers) MUST be logged in
  decimal (base-10) format. TODO: see issue 10

TODO: list all possible triggers per event type

TODO: make it clear which events are "normal" and which are "only if you really
need this" (normal = probably TRANSPORT TX/RX and RECOVERY basics and HTTP basics)

# QUIC event definitions

## CONNECTIVITY

### CONNECTION_ATTEMPT

### CONNECTION_NEW

### CONNECTION_ID_UPDATE

TODO: mention that CIDs can be logged in hex

### MIGRATION-related events
e.g., PATH_UPDATE

TODO: read up on the draft how migration works and whether to best fit this here or in TRANSPORT

## SECURITY

### HEADER_DECRYPT_ERROR
~~~~
{ mask, error }
~~~~

### PACKET_DECRYPT_ERROR
~~~~
{ key, error }
~~~~

### KEY_UPDATE
~~~~
{ type = "Initial | handshake | 1RTT", value }
~~~~

### KEY_RETIRED
~~~~
{ value } # initial encryption level is implicitly deleted
~~~~

### CIPHER_UPDATE

## TRANSPORT

### PACKET_SENT

Triggers:

* "DEFAULT"
* "RETRANSMIT_REORDERING" // draft-19 6.1.1
* "RETRANSMIT_TIMEOUT" // draft-19 6.1.2
* "RETRANSMIT_CRYPTO" // draft-19 6.2
* "RETRANSMIT_PTO" // draft-19 6.3

Data:

~~~
{
    packet_type:PacketType,
    header:PacketHeader,
    frames:Array<QuicFrame>
}
~~~

Notes:

* We don't explicitly log the encryption_level or packet_number_space: the
  packet_type specifies this by inference (assuming correct implementation)

### PACKET_RECEIVED

Triggers:

* "DEFAULT"

Data:

~~~
{
    packet_type:PacketType,
    header:PacketHeader,
    frames:Array<QuicFrame>
}
~~~

Notes:

* We don't explicitly log the encryption_level or packet_number_space: the
  packet_type specifies this by inference (assuming correct implementation)


### VERSION_UPDATE
TODO: maybe name VERSION_SELECTED ?

### TRANSPORT_PARAMETERS_UPDATE

### ALPN_UPDATE
TODO: should this be in HTTP?
~~~~
{ alpn }
~~~~

### STREAM_STATE_UPDATE
* IDLE
* OPEN
* CLOSED
* HALF_CLOSED_REMOTE
* HALF_CLOSED_LOCAL
* DESTROYED // memory freed

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

TODO: do we need all of these? How do implementations actually handle this in practice?

### FLOW_CONTROL_UPDATE
* type = connection
* type = stream + id = streamid

TODO: check state machine in QUIC transport draft

## RECOVERY

### CC_STATE_UPDATE

### METRIC_UPDATE
* CWND
* BYTES_IN_FLIGHT
* RTT
* SSTHRESH
* PACING_RATE

TODO: split these up into separate events?
TODO: allow more than 1 of these in a single METRIC_UPDATE event? (cfr. quic-trace TransportState)


### LOSS_ALARM_SET

### LOSS_ALARM_FIRED

### PACKET_LOST

### PACKET_ACKNOWLEDGED

### PACKET_RETRANSMIT
TODO: only if a packet is retransmit in-full, which many stacks don't do. Need something more flexible.

# HTTP/3 event definitions

## HTTP

## QPACK

## PRIORITIZATION

## PUSH

# Security Considerations

TBD

# IANA Considerations

TBD

--- back

# QUIC DATA type definitions

## PacketType

~~~
enum PacketType {
    INITIAL,
    HANDSHAKE,
    ZERORTT = "0RTT",
    ONERTT = "1RTT",
    RETRY,
    VERSION_NEGOTIATION,
    UNKOWN
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

## QUIC Frames

~~~
type QuicFrame = AckFrame | StreamFrame | ResetStreamFrame | ConnetionCloseFrame | MaxDataFrame | MaxStreamDataFrame | UnknownFrame;
~~~

### AckFrame

~~~
class AckFrame{
    frame_type:string = "ACK";

    ack_delay:string;
    acked_ranges:Array<AckRange>;

    ect1:string;
    ect0:string;
    ce:string;
}

class AckRange{
    from:string;
    to:string; // up to and including
}
~~~

### StreamFrame

~~~
class StreamFrame{
  frame_type:string = "STREAM";

  id:string;

  // These three MUST always be set
  // If not present in the Frame type, log their default values
  offset:string;
  length:string;
  fin:boolean;
}
~~~

### ResetStreamFrame
~~~
class ResetStreamFrame{
    frame_type:string = "RESET_STREAM";

    id:string;
    error_code:ApplicationError | number;
    final_offset:string;
}
~~~

### ConnectionCloseFrame

~~~

type ErrorSpace = "TRANSPORT" | "APPLICATION";

class ConnectionCloseFrame{
    frame_type:string = "CONNECTION_CLOSE";

    error_space:ErrorSpace;
    error_code:TransportError | ApplicationError | number;
    reason:string;

    trigger_frame_type?:number; // TODO: should be more defined, but we don't have a FrameType enum atm...
}
~~~

### MaxDataFrame

~~~
class MaxDataFrame{
    stream_type:string = "MAX_DATA";

    maximum:string;
}
~~~

### MaxStreamDataFrame

~~~
class MaxStreamDataFrame{
    stream_type:string = "MAX_STREAM_DATA";

    id:string;
    maximum:string;
}
~~~

### UnknownFrame

~~~
class UnknownFrame{
    frame_type:string = "UNKNOWN";
}
~~~

### TransportError
~~~
enum TransportError {
    NO_ERROR,
    INTERNAL_ERROR,
    SERVER_BUSY,
    APPLICATION_FLOW_CONTROL_ERROR, // 0x3
    STREAM_FLOW_CONTROL_ERROR,  // 0x4
    STREAM_STATE_ERROR,
    FINAL_SIZE_ERROR,
    FRAME_ENCODING_ERROR,
    TRANSPORT_PARAMETER_ERROR,
    PROTOCOL_VIOLATION,
    INVALID_MIGRATION,
    CRYPTO_ERROR
}
~~~


# HTTP/3 DATA type definitions


### ApplicationError
~~~
enum ApplicationError{
    HTTP_NO_ERROR,
    HTTP_WRONG_SETTING_DIRECTION,
    HTTP_PUSH_REFUSED,
    HTTP_INTERNAL_ERROR,
    HTTP_PUSH_ALREADY_IN_CACHE,
    HTTP_REQUEST_CANCELLED,
    HTTP_INCOMPLETE_REQUEST,
    HTTP_CONNECT_ERROR,
    HTTP_EXCESSIVE_LOAD,
    HTTP_VERSION_FALLBACK,
    HTTP_WRONG_STREAM,
    HTTP_LIMIT_EXCEEDED,
    HTTP_DUPLICATE_PUSH,
    HTTP_UNKNOWN_STREAM_TYPE,
    HTTP_WRONG_STREAM_COUNT,
    HTTP_CLOSED_CRITICAL_STREAM,
    HTTP_WRONG_STREAM_DIRECTION,
    HTTP_EARLY_RESPONSE,
    HTTP_MISSING_SETTINGS,
    HTTP_UNEXPECTED_FRAME,
    HTTP_REQUEST_REJECTED,
    HTTP_GENERAL_PROTOCOL_ERROR,
    HTTP_MALFORMED_FRAME
}
~~~

# Change Log

## Since draft-marx-quic-logging-event-definitions-00:

- None yet.

# Design Variations

TBD

# Acknowledgements

Thanks to Jana Iyengar, Brian Trammell, Dmitri Tikhonov, Jari Arkko, Marcus Ihlar,
Victor Vasiliev and Lucas Pardue for their feedback and suggestions.

