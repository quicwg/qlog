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


This document uses the ["TypeScript" language](https://www.typescriptlang.org/) to
describe its schema in. We use TypeScript because it is less verbose than
JSON-schema and almost as expressive. It also makes it easier to include these
definitions directly into a web-based tool. The main conventions a reader should
be aware of are:

* obj? : this object is optional
* type1 &#124; type2 : a union of these two types
* obj&#58;type : this object has this concrete type
* obj&#91;&#93; : this object is an array (which can contain any type of object)
* obj&#58;Array&lt;type&gt; : this object is an array of this type
* number : identifies either an integer, float or double in TypeScript. In this
  document, number always means an integer.

* TODO: list all possible triggers per event type
* TODO: make it clear which events
are "normal" and which are "only if you really need this" (normal = probably
TRANSPORT and RECOVERY and HTTP)

# QUIC event definitions

## CONNECTIVITY

### CONNECTION_ATTEMPT

### CONNECTION_NEW

### CONNECTION_ID_UPDATE

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

### VERSION_UPDATE
TODO: maybe name VERSION_SELECTED ?

### TRANSPORT_PARAMETERS_UPDATE

### ALPN_UPDATE
TODO: should this be in HTTP?
~~~~
{ alpn }
~~~~

### STREAM_STATE_UPDATE
* NEW
* CLOSED
* DESTROYED
* HALF_CLOSED
* HALF_OPEN
* ...

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

# Change Log

## Since draft-marx-quic-logging-event-definitions-00:

- None yet.

# Design Variations

TBD

# Acknowledgements

Thanks to Jana Iyengar, Brian Trammell, Dmitri Tikhonov, Jari Arkko, Marcus Ihlar,
Victor Vasiliev and Lucas Pardue for their feedback and suggestions.

