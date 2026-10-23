---
title: QUIC event definitions for qlog
docname: draft-ietf-quic-qlog-quic-events-latest
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
  -
    ins: L. Pardue
    name: Lucas Pardue
    org: Apple
    email: lucas@lucaspardue.com
    role: editor

normative:

  QLOG-MAIN:
    I-D.ietf-quic-qlog-main-schema

informative:

--- abstract

This document describes a qlog event schema containing concrete qlog event
definitions and their metadata for the core QUIC protocol and selected
extensions.

--- note_Note_to_Readers

> Note to RFC editor: Please remove this section before publication.

Feedback and discussion are welcome at
[https://github.com/quicwg/qlog](https://github.com/quicwg/qlog). Readers are
advised to refer to the "editor's draft" at that URL for an up-to-date version
of this document.

--- middle

# Introduction

This document defines a qlog event schema ({{Section 8 of QLOG-MAIN}})
containing concrete events for the core QUIC protocol (see
{{!QUIC-TRANSPORT=RFC9000}}, {{!QUIC-RECOVERY=RFC9002}}, and
{{!QUIC-TLS=RFC9001}}) and some of its extensions (see
{{!QUIC-DATAGRAM=RFC9221}} and {{!GREASEBIT=RFC9287}}).


The event namespace with identifier `quic` is defined; see {{schema-def}}. In
this namespace multiple events derive from the qlog abstract Event class
({{Section 7 of QLOG-MAIN}}), each extending the "data" field and defining their
"name" field values and semantics. The data types that the events use are
defined in {{quic-data-types}}.

## Use of group IDs

QUIC's Original Destination Connection ID (ODCID) can be used as the value of
the qlog `group_id` field. The ODCID is the connection ID that the client
chooses for its first Initial packet. It stays the same for the whole
connection, unlike the connection IDs that endpoints use, which can change. It
can also link packets such as Retry and Version Negotiation to the connection.

The ODCID can also be used as the qlog filename or file identifier, optionally
suffixed by the vantage point type. For example, abcd1234_server.qlog would
contain the server-side trace of the connection with ODCID abcd1234.

## Raw packet and frame information

Protected QUIC packets (Initial, 0-RTT, Handshake, and 1-RTT) end with an AEAD
authentication tag. Every cipher suite that QUIC version 1 can use has a
16-byte tag; see {{Section 5.3 of QUIC-TLS}}. When calculating the lengths in
RawInfo fields ({{Section 10 of QLOG-MAIN}}) for these packets, the tag is
treated as a 16-byte trailer.

## Events without a known connection {#handling-unknown-connections}

A qlog trace is typically associated with a single QUIC connection. However,
some events cannot be tied to a specific connection, especially on the server.
For example, a `packet_dropped` event ({{quic-packetdropped}}) with the trigger
`connection_unknown` is for a packet that matches no known connection.

There are various ways to handle these events, each with tradeoffs between file
size overhead, flexibility, ease of use, and ease of implementation. Some
options include:

* Log them in a separate endpoint-wide trace, or use a special `group_id` value,
  not associated with a single connection.
* Log them in the most recently used trace.
* Use additional heuristics to identify the connection, for example the
  four-tuple in addition to the connection ID.
* Buffer events until they can be assigned to a connection, for example events
  about the Version Negotiation and Retry packets that a server sends before it
  creates connection state.

## Notational Conventions

{::boilerplate bcp14-tagged}

The event and data structure definitions in this document are expressed
in the Concise Data Definition Language {{!CDDL=RFC8610}} and its
extensions described in {{Section 1.2 of QLOG-MAIN}}.

This document uses the following from {{QLOG-MAIN}}: the event namespace and
event type concepts; the name, data, tuple, group_id, and time-related fields;
and the RawInfo type.

Events are defined with an importance level as described in {{Section 8.3 of
QLOG-MAIN}}.

As is the case for {{QLOG-MAIN}}, the qlog schema definitions in this document
are intentionally agnostic to serialization formats. The choice of format is an
implementation decision.

# Event Schema Definition {#schema-def}

This document describes how the core QUIC protocol and selected extensions can
be expressed in qlog using a newly defined event schema. Per the requirements in
{{Section 8 of QLOG-MAIN}}, this document registers the `quic` namespace. The
event schema URI is `urn:ietf:params:qlog:events:quic`.

## Draft Event Schema Identification
{:removeinrfc="true"}

Only implementations of the final, published RFC can use the events belonging to
the event schema with the URI `urn:ietf:params:qlog:events:quic`. Until such an
RFC exists, implementations MUST NOT identify themselves using this URI.

Implementations of draft versions of the event schema MUST append the string
"-" and the corresponding draft number to the URI. For example, draft 07 of this
document is identified using the URI `urn:ietf:params:qlog:events:quic-07`.

The namespace identifier itself is not affected by this requirement.

# QUIC Event Overview

{{quic-events}} summarizes the name value of each event type that is defined in
this specification.

| Name value                            | Importance |  Definition |
|:--------------------------------------|:-----------| :------------|
| quic:server_listening         | Extra      | {{quic-serverlistening}} |
| quic:connection_started       | Base       | {{quic-connectionstarted}} |
| quic:connection_closed        | Base       | {{quic-connectionclosed}} |
| quic:connection_id_updated    | Base       | {{quic-connectionidupdated}} |
| quic:spin_bit_updated         | Base       | {{quic-spinbitupdated}} |
| quic:connection_state_updated | Base       | {{quic-connectionstateupdated}} |
| quic:tuple_assigned            | Base      | {{quic-tupleassigned}} |
| quic:mtu_updated              | Extra      | {{quic-mtuupdated}} |
| quic:version_information      | Core       | {{quic-versioninformation}} |
| quic:alpn_information         | Core       | {{quic-alpninformation}} |
| quic:parameters_set           | Core       | {{quic-parametersset}} |
| quic:parameters_restored         | Base       | {{quic-parametersrestored}} |
| quic:packet_sent                 | Core       | {{quic-packetsent}} |
| quic:packet_received             | Core       | {{quic-packetreceived}} |
| quic:packet_dropped              | Base       | {{quic-packetdropped}} |
| quic:packet_buffered             | Base       | {{quic-packetbuffered}} |
| quic:packets_acked               | Extra      | {{quic-packetsacked}} |
| quic:udp_datagrams_sent              | Extra      | {{quic-udpdatagramssent}} |
| quic:udp_datagrams_received          | Extra      | {{quic-udpdatagramsreceived}} |
| quic:udp_datagram_dropped            | Extra      | {{quic-udpdatagramdropped}} |
| quic:stream_state_updated        | Base       | {{quic-streamstateupdated}} |
| quic:frames_created            | Extra      | {{quic-framescreated}} |
| quic:frames_parsed            | Extra      | {{quic-framesparsed}} |
| quic:stream_data_moved                | Base       | {{quic-streamdatamoved}} |
| quic:datagram_data_moved              | Base       | {{quic-datagramdatamoved}} |
| quic:connection_data_blocked_updated              | Extra       | {{quic-connectiondatablockedupdated}} |
| quic:stream_data_blocked_updated              | Extra       | {{quic-streamdatablockedupdated}} |
| quic:datagram_data_blocked_updated              | Extra       | {{quic-datagramdatablockedupdated}} |
| quic:migration_state_updated          | Extra      | {{quic-migrationstateupdated}} |
| quic:timer_updated                    | Extra      | {{quic-timerupdated}} |
| quic:key_updated                  | Base       | {{quic-keyupdated}} |
| quic:key_discarded                | Base       | {{quic-keydiscarded}} |
| quic:recovery_parameters_set               | Base       | {{quic-recoveryparametersset}} |
| quic:recovery_metrics_updated              | Core       | {{quic-recoverymetricsupdated}} |
| quic:congestion_state_updated     | Base       | {{quic-congestionstateupdated}} |
| quic:packet_lost                  | Core       | {{quic-packetlost}} |
| quic:marked_for_retransmit        | Extra      | {{quic-markedforretransmit}} |
| quic:ecn_state_updated            | Extra      | {{quic-ecnstateupdated}} |
{: #quic-events title="QUIC Events"}

QUIC events extend the `$ProtocolEventData` extension point defined in
{{Section 8.2 of QLOG-MAIN}}. Additionally, they allow for direct extensibility by their use of
per-event extension points via the `$$` CDDL "group socket" syntax, as also
described in {{Section 8.2 of QLOG-MAIN}}.

~~~ cddl
QuicEventData = QUICServerListening /
                QUICConnectionStarted /
                QUICConnectionClosed /
                QUICConnectionIDUpdated /
                QUICSpinBitUpdated /
                QUICConnectionStateUpdated /
                QUICTupleAssigned /
                QUICMTUUpdated /
                QUICVersionInformation /
                QUICALPNInformation /
                QUICParametersSet /
                QUICParametersRestored /
                QUICPacketSent /
                QUICPacketReceived /
                QUICPacketDropped /
                QUICPacketBuffered /
                QUICPacketsAcked /
                QUICUDPDatagramsSent /
                QUICUDPDatagramsReceived /
                QUICUDPDatagramDropped /
                QUICStreamStateUpdated /
                QUICFramesCreated /
                QUICFramesParsed /
                QUICStreamDataMoved /
                QUICDatagramDataMoved /
                QUICConnectionDataBlockedUpdated /
                QUICStreamDataBlockedUpdated /
                QUICDatagramDataBlockedUpdated /
                QUICMigrationStateUpdated /
                QUICTimerUpdated /
                QUICKeyUpdated /
                QUICKeyDiscarded /
                QUICRecoveryParametersSet /
                QUICRecoveryMetricsUpdated /
                QUICCongestionStateUpdated /
                QUICPacketLost /
                QUICMarkedForRetransmit /
                QUICECNStateUpdated

$ProtocolEventData /= QuicEventData
~~~
{: #quicevent-data-def title="QuicEventData definition and ProtocolEventData
extension"}

The concrete QUIC event types are further defined below, their type identifier
is the heading name. The subdivisions in sections on Connectivity, Transport,
Security, and Recovery are purely for readability.

# Connectivity events {#conn-ev}

## server_listening {#quic-serverlistening}

The `server_listening` event is emitted when the server starts accepting
connections. It has Extra importance level.

~~~ cddl
QUICServerListening = {
    ? ip_v4: IPAddress
    ? port_v4: uint16
    ? ip_v6: IPAddress
    ? port_v6: uint16

    ; the server will always answer client Initial packets with a Retry
    ; packet (no 1-RTT connection setups by choice)
    ? retry_required: bool

    * $$quic-serverlistening-extension
}
~~~
{: #quic-serverlistening-def title="QUICServerListening definition"}

Some QUIC stacks do not handle sockets directly, so they cannot log IP
addresses or ports.

## connection_started {#quic-connectionstarted}

The `connection_started` event is emitted when a client attempts a new
connection, or when a server accepts one. It overlaps with the
`connection_state_updated` event, but it also logs the local and remote
endpoint information. It has Base importance level.

~~~ cddl
QUICConnectionStarted = {
    local: TupleEndpointInfo
    remote: TupleEndpointInfo

    * $$quic-connectionstarted-extension
}
~~~
{: #quic-connectionstarted-def title="QUICConnectionStarted definition"}

Some QUIC stacks do not handle sockets directly, so they cannot log IP
addresses or ports. All fields of TupleEndpointInfo
({{tupleendpointinfo-def}}) are optional, so such a stack can log `local` and
`remote` with only the fields it knows, such as `connection_ids`.

## connection_closed {#quic-connectionclosed}

The `connection_closed` event is emitted when a connection closes, typically
because of an error or a timeout. It has Base importance level.

This event overlaps with the `connection_state_updated` event and the
CONNECTION_CLOSE frame. However, when analyzing large deployments, it can be
useful to have a single event for each closure, with a `reason` field for more
detail. This event can also log closures due to timeouts or explicit
application actions, such as racing several connections and aborting the
slowest, which the other events cannot easily capture.

The `connection_closed` event is logged when the local endpoint does one of the
following; see {{Section 10 of QUIC-TRANSPORT}}:

* silently discards the connection after an idle timeout;
* sends a CONNECTION_CLOSE frame, and enters the closing state;
* receives a CONNECTION_CLOSE frame, and enters the draining state; or
* receives a Stateless Reset, and enters the draining state.

Later changes, such as leaving the closing or draining state, are logged with
the `connection_state_updated` event.

QUIC has two kinds of connection error, transport errors and application
errors, each with defined codes and semantics; see {{Section 20 of
QUIC-TRANSPORT}}. An implementation can also have internal errors, which it
might or might not map to these codes. So this event can carry two levels of
error: `connection_error` or `application_error` for the QUIC error, and
`internal_code` for a more specific internal error.

If the error code does not map to a known error string, the connection_error or
application_error value of "unknown" type can be used and the raw value captured
in the error_code field; a numerical value without variable-length integer
encoding.

~~~ cddl
QUICConnectionClosed = {

    ; which side closed the connection
    ? initiator: Initiator
    ? connection_error: $TransportError /
                        CryptoError
    ? application_error: $ApplicationError

    ; if connection_error or application_error === "unknown"
    ? error_code: uint64

    ? internal_code: uint64
    ? reason: text
    ? trigger:
        "idle_timeout" /
        "application" /
        "error" /
        "version_mismatch" /
        ; when received from peer
        "stateless_reset" /
        "aborted" /
        ; when it is unclear what triggered the CONNECTION_CLOSE
        "unspecified"

    * $$quic-connectionclosed-extension
}
~~~
{: #quic-connectionclosed-def title="QUICConnectionClosed definition"}

Implementations SHOULD use the most descriptive `trigger` value that they can
determine. This is often clear at the endpoint that closes the connection, but
can be less clear at the endpoint that receives the CONNECTION_CLOSE frame.


## connection_id_updated {#quic-connectionidupdated}

The `connection_id_updated` event is emitted when either endpoint updates its
current connection ID. This typically happens rarely during a connection, so
logging this event is more efficient than logging the connection ID in every
`packet_sent` or `packet_received` event. It has Base importance level.

The `connection_id_updated` event is viewed from the perspective of the
endpoint applying the new ID. When the endpoint receives a new connection ID
from the peer, the `initiator` field is "remote". When the endpoint updates its
own connection ID, the `initiator` field is "local".

~~~ cddl
QUICConnectionIDUpdated = {
    initiator: Initiator
    ? old: ConnectionID
    ? new: ConnectionID

    * $$quic-connectionidupdated-extension
}
~~~
{: #quic-connectionidupdated-def title="QUICConnectionIDUpdated definition"}

## spin_bit_updated {#quic-spinbitupdated}

The `spin_bit_updated` event is emitted when the value of the QUIC latency spin
bit changes; see {{Section 17.4 of QUIC-TRANSPORT}}. It SHOULD NOT be emitted
when the spin bit is set to the value it already has. It has Base importance
level.

~~~ cddl
QUICSpinBitUpdated = {
    state: bool

    * $$quic-spinbitupdated-extension
}
~~~
{: #quic-spinbitupdated-def title="QUICSpinBitUpdated definition"}

## connection_state_updated {#quic-connectionstateupdated}

The `connection_state_updated` event is emitted when the connection changes
state, to track progress through the QUIC handshake and connection close. It
has Base importance level.

{{QUIC-TRANSPORT}} does not define a complete set of connection states or their
transitions, though it names some, such as the closing and draining states.
This document defines the states most likely to be useful for debugging QUIC
connections; the list is not exhaustive.

QUIC implementations SHOULD log the BaseConnectionStates, and can add the
GranularConnectionStates when more in-depth debugging is required. Tools
SHOULD handle both kinds equally.

~~~ cddl
QUICConnectionStateUpdated = {
    ? old: $ConnectionState
    new: $ConnectionState

    * $$quic-connectionstateupdated-extension
}

BaseConnectionStates =
    ; Initial packet sent/received
    "attempted" /

    ; Handshake packet sent/received
    "handshake_started" /

    ; Both sent a TLS Finished message
    ; and verified the peer's TLS Finished message
    ; 1-RTT packets can be sent
    ; RFC 9001 Section 4.1.1
    "handshake_complete" /

    ; CONNECTION_CLOSE sent/received,
    ; stateless reset received or idle timeout
    "closed"

GranularConnectionStates =
    ; RFC 9000 Section 8.1
    ; client sent Handshake packet OR
    ; client used connection ID chosen by the server OR
    ; client used valid address validation token
    "peer_validated" /

    ; 1-RTT data can be sent by the server,
    ; but handshake is not done yet
    ; (server has sent TLS Finished; sometimes called 0.5 RTT data)
    "early_write" /

    ; HANDSHAKE_DONE sent/received.
    ; RFC 9001 Section 4.1.2
    "handshake_confirmed" /

    ; CONNECTION_CLOSE sent
    "closing" /

    ; CONNECTION_CLOSE or Stateless Reset received
    "draining" /

    ; draining or closing period done, connection state discarded
    "closed"

$ConnectionState /= BaseConnectionStates / GranularConnectionStates
~~~
{: #quic-connectionstateupdated-def title="QUICConnectionStateUpdated definition"}

The `connection_state_updated` event overlaps with the `connection_closed` and
`connection_started` events, and with the frames logged in events such as
`packet_received`. Still, it can be useful to log state transitions separately,
especially if they map to an internal state machine. Implementations can
therefore use other ConnectionState values that match their internal logic.
Tools SHOULD handle these custom states in a similar way to the states defined
in this document.

## tuple_assigned {#quic-tupleassigned}

The `tuple_assigned` event associates a TupleID with the details of a network
tuple, such as its IP addresses, ports, and connection IDs. It has Base
importance level.

As described in {{Section 7.2 of QLOG-MAIN}}, each qlog event can be linked to
a single network tuple by its top-level `tuple` field, whose value is a
TupleID. Encoding tuple details, such as IP addresses or connection IDs, into
the TupleID itself can be cumbersome. This event records them separately, so
TupleIDs can stay short, and their details can be updated as the connection
evolves.

~~~ cddl
QUICTupleAssigned = {
    tuple_id: TupleID

    ; the information for traffic going towards the remote receiver
    ? tuple_remote: TupleEndpointInfo

    ; the information for traffic coming in at the local endpoint
    ? tuple_local: TupleEndpointInfo

    * $$quic-tupleassigned-extension
}
~~~
{: #quic-tupleassigned-def title="QUICTupleAssigned definition"}

Implementations choose their own `tuple_id` values. For example, a TupleID can
be an incrementing integer, the first Destination Connection ID associated with
the tuple (or its sequence number), or the two endpoint IP addresses or a hash
of them.

The empty string ("") is a valid TupleID, and it is the default for events that
do not set the `tuple` field. So the initial tuple of a QUIC connection, on
which the handshake occurs (see {{quic-connectionstarted}}), is implicitly
associated with the TupleID "". Details for this default tuple can be logged
with a `tuple_assigned` event whose `tuple_id` is "".

Because a tuple's details can change during the connection, a TupleID can
appear in several `tuple_assigned` events, and the latest one holds its current
details. The first `tuple_assigned` event for a TupleID indicates that the
TupleID was created, and later ones indicate updates. An event with both
`tuple_local` and `tuple_remote` omitted indicates that the TupleID was
abandoned.

## mtu_updated {#quic-mtuupdated}

The `mtu_updated` event indicates that the estimated Path MTU was updated. This
happens as part of Path MTU discovery; see {{Section 14 of QUIC-TRANSPORT}}. It
has Extra importance level.

~~~ cddl
QUICMTUUpdated = {
    ? old: uint32
    new: uint32

    ; at some point, MTU discovery stops, as a "good enough"
    ; packet size has been found
    ? done: bool .default false

    * $$quic-mtuupdated-extension
}
~~~
{: #quic-mtuupdated-def title="QUICMTUUpdated definition"}

# Transport events  {#quic-ev}

## version_information {#quic-versioninformation}

The `version_information` event supports QUIC version negotiation; see {{Section
6 of QUIC-TRANSPORT}}. It has Core importance level.

QUIC endpoints each have their own list of QUIC versions they support. The
client uses the most likely version in their first initial. If the server does
not support that version, it replies with a Version Negotiation packet, which
contains its supported versions. From this, the client selects a version. The
`version_information` event aggregates all this information in a single event
type. It also allows logging of supported versions at an endpoint without actual
version negotiation needing to happen.

~~~ cddl
QUICVersionInformation = {
    ? server_versions: [+ QuicVersion]
    ? client_versions: [+ QuicVersion]
    ? chosen_version: QuicVersion

    * $$quic-versioninformation-extension
}
~~~
{: #quic-versioninformation-def title="QUICVersionInformation definition"}

Intended use:

- When sending an initial, the client logs this event with `client_versions` and
  `chosen_version` set
- Upon receiving a client initial with a supported version, the server logs this
  event with `server_versions` and `chosen_version` set
- Upon receiving a client initial with an unsupported version, the server logs
  this event with `server_versions` set and `client_versions` to the
  single-element array containing the client's attempted version. The absence of
  chosen_version implies no overlap was found
- Upon receiving a version negotiation packet from the server, the client logs
  this event with `client_versions` set and `server_versions` to the versions in
  the version negotiation packet and chosen_version to the version it will use
  for the next initial packet. If the client receives a set of `server_versions`
  with no viable overlap with its own supported versions, this event should be
  logged without the `chosen_version` set

## alpn_information {#quic-alpninformation}

The `alpn_information` event supports Application-Layer Protocol Negotiation
(ALPN) over the QUIC transport; see {{?RFC7301}} and {{Section 8.1 of
QUIC-TLS}}. It has Core importance level.

QUIC endpoints are configured with a list of supported ALPN identifiers. Clients send the list in a TLS ClientHello, and servers match against their list. On success, a single ALPN identifier is chosen and sent back in a TLS ServerHello. If no match is found, the connection is closed.

ALPN identifiers are byte sequences that may be presentable as UTF-8.
The `ALPNIdentifier` type supports either format. Implementations SHOULD log at
least one format, but MAY log both or none.

~~~ cddl
QUICALPNInformation = {
    ? server_alpns: [* ALPNIdentifier]
    ? client_alpns: [* ALPNIdentifier]
    ? chosen_alpn: ALPNIdentifier

    * $$quic-alpninformation-extension
}

ALPNIdentifier = {
  ? byte_value: hexstring
  ? string_value: text
}
~~~
{: #quic-alpninformation-def title="QUICALPNInformation definition"}

Intended use:

- When sending an initial, the client logs this event with `client_alpns` set
- When receiving an initial with a supported alpn, the server logs this event
  with `server_alpns` set, `client_alpns` equalling the client-provided list,
  and chosen_alpn to the value it will send back to the client.
- When receiving an initial with an alpn, the client logs this event with
  `chosen_alpn` to the received value.
- Alternatively, a client can choose to not log the first event, but wait for
  the receipt of the server initial to log this event with both `client_alpns`
  and `chosen_alpn` set.

## parameters_set {#quic-parametersset}

The `parameters_set` event groups settings from several sources, such as
transport parameters and the TLS cipher suite, into a single event. This keeps
the number of events low, and lets a reader reason about what the settings do
without needing to know which mechanism set each one. It has Core importance
level.

Most of these settings are set once and never change. However, they are often
set at different times during the connection, so a trace can contain several
`parameters_set` events with different fields set.

Some settings have two values: one set by the local endpoint, and one requested
by the peer. The `initiator` field says which side the settings in an event
come from, so it MUST be correct for every setting in that event. Local and
remote settings MUST be logged in separate events. If the local endpoint
changes its behavior based on the peer's settings, the outcome can be logged
with a new event type, or with fields added through
`$$quic-parametersset-extension`; see {{Section 8.2 of QLOG-MAIN}}.

Each setting starts the connection with its default value, or with no value if
it has no default. A `parameters_set` event that includes a setting replaces
its previous value; settings that the event omits keep their values.

Implementations are not required to recognize, process, or support every
parameter that they receive. For example, QUIC implementations ignore
transport parameters that they do not support; see {{Section 7.4.2 of
QUIC-TRANSPORT}}. The `unknown_parameters` field can log the raw values of such
parameters, for example reserved (GREASE) parameters, private extensions, or
experiments.

In the case of connection resumption and 0-RTT, some of the server's parameters
are stored up-front at the client and used for the initial connection startup.
They are later updated with the server's reply. In these cases, utilize the
separate `parameters_restored` event to indicate the initial values, and this
event to indicate the updated values, as normal.

~~~ cddl
QUICParametersSet = {
    ? initiator: Initiator

    ; true if valid session ticket was received
    ? resumption_allowed: bool

    ; true if early data extension was enabled on the TLS layer
    ? early_data_enabled: bool

    ; e.g., "AES_128_GCM_SHA256"
    ? tls_cipher: text

    ; RFC9000
    ? original_destination_connection_id: ConnectionID
    ? initial_source_connection_id: ConnectionID
    ? retry_source_connection_id: ConnectionID
    ? stateless_reset_token: StatelessResetToken
    ? disable_active_migration: bool
    ? max_idle_timeout: uint64
    ? max_udp_payload_size: uint64
    ? ack_delay_exponent: uint64
    ? max_ack_delay: uint64
    ? active_connection_id_limit: uint64
    ? initial_max_data: uint64
    ? initial_max_stream_data_bidi_local: uint64
    ? initial_max_stream_data_bidi_remote: uint64
    ? initial_max_stream_data_uni: uint64
    ? initial_max_streams_bidi: uint64
    ? initial_max_streams_uni: uint64
    ? preferred_address: PreferredAddress
    ? unknown_parameters: [* UnknownParameter]

    ; RFC9221
    ? max_datagram_frame_size: uint64

    ; RFC9287
    ; true if present, absent or false if extension not negotiated
    ? grease_quic_bit: bool

    ; draft-ietf-quic-reliable-stream-reset
    ; true if present, absent or false if extension not negotiated
    ? reset_stream_at: bool

    * $$quic-parametersset-extension
}

PreferredAddress = {
    ? ip_v4: IPAddress
    ? port_v4: uint16
    ? ip_v6: IPAddress
    ? port_v6: uint16
    connection_id: ConnectionID
    stateless_reset_token: StatelessResetToken
}

UnknownParameter = {
    id: uint64
    ? value: hexstring
}
~~~
{: #quic-parametersset-def title="QUICParametersSet definition"}

## parameters_restored {#quic-parametersrestored}

When using QUIC 0-RTT, clients are expected to remember and restore the server's
transport parameters from the previous connection. The `parameters_restored`
event is used to indicate which parameters were restored and to which values
when utilizing 0-RTT. It has Base importance level.

Note that not all transport parameters should be restored (many are even
prohibited from being re-utilized). The ones listed here are the ones expected
to be useful for correct 0-RTT usage.

~~~ cddl
QUICParametersRestored = {

    ; RFC9000
    ? disable_active_migration: bool
    ? max_idle_timeout: uint64
    ? max_udp_payload_size: uint64
    ? active_connection_id_limit: uint64
    ? initial_max_data: uint64
    ? initial_max_stream_data_bidi_local: uint64
    ? initial_max_stream_data_bidi_remote: uint64
    ? initial_max_stream_data_uni: uint64
    ? initial_max_streams_bidi: uint64
    ? initial_max_streams_uni: uint64

    ; RFC9221
    ? max_datagram_frame_size: uint64

    ; RFC9287
    ; can only be restored at the client.
    ; servers MUST NOT restore this parameter!
    ? grease_quic_bit: bool

    * $$quic-parametersrestored-extension
}
~~~
{: #quic-parametersrestored-def title="QUICParametersRestored definition"}

## packet_sent {#quic-packetsent}

The `packet_sent` event indicates that a QUIC packet was sent. It has Core
importance level.

~~~ cddl
QUICPacketSent = {
    header: PacketHeader
    ? frames: [* $QuicFrame]

    ; only if header.packet_type === "stateless_reset"
    ; is always 128 bits in length.
    ? stateless_reset_token: StatelessResetToken

    ; only if header.packet_type === "version_negotiation"
    ? supported_versions: [+ QuicVersion]
    ? raw: RawInfo
    ? datagram_payload_checksum: uint32
    ? is_mtu_probe_packet: bool .default false

    ? trigger:
      ; RFC 9002 Section 6.1.1
      "retransmit_reordered" /
      ; RFC 9002 Section 6.1.2
      "retransmit_timeout" /
      ; RFC 9002 Section 6.2.4
      "pto_probe" /
      ; RFC 9002 6.2.3
      "retransmit_crypto" /
      ; needed for some CCs to figure out bandwidth allocations
      ; when there are no normal sends
      "cc_bandwidth_probe"

    * $$quic-packetsent-extension
}
~~~
{: #quic-packetsent-def title="QUICPacketSent definition"}

The encryption level and packet number space are not logged explicitly,
because `header.packet_type` implies them for the packet types that have them.

The `datagram_payload_checksum` field is described in {{packet-coalescing}}.

## packet_received {#quic-packetreceived}

The `packet_received` event indicates that a QUIC packet was received. It has
Core importance level.

~~~ cddl
QUICPacketReceived = {
    header: PacketHeader
    ? frames: [* $QuicFrame]

    ; only if header.packet_type === "stateless_reset"
    ; Is always 128 bits in length.
    ? stateless_reset_token: StatelessResetToken

    ; only if header.packet_type === "version_negotiation"
    ? supported_versions: [+ QuicVersion]
    ? raw: RawInfo
    ? datagram_payload_checksum: uint32

    ? trigger:
        ; if packet was buffered because it couldn't be
        ; decrypted before
        "keys_available"

    * $$quic-packetreceived-extension
}
~~~
{: #quic-packetreceived-def title="QUICPacketReceived definition"}

The encryption level and packet number space are not logged explicitly,
because `header.packet_type` implies them for the packet types that have them.

The `datagram_payload_checksum` field is described in {{packet-coalescing}}.

## packet_dropped {#quic-packetdropped}

The `packet_dropped` event indicates that a QUIC packet was dropped. It has
Base importance level.

~~~ cddl
QUICPacketDropped = {

    ; Primarily packet_type should be filled here,
    ; as other fields might not be decryptable or parsable
    ? header: PacketHeader
    ? raw: RawInfo
    ? datagram_payload_checksum: uint32
    ? details: {* text => any}
    ? trigger:
        "internal_error" /
        "rejected" /
        "unsupported" /
        "invalid" /
        "duplicate" /
        "connection_unknown" /
        "decryption_failure" /
        "key_unavailable" /
        "general"

    * $$quic-packetdropped-extension
}
~~~
{: #quic-packetdropped-def title="QUICPacketDropped definition"}

The `trigger` field gives a general reason for dropping the packet, and the
`details` field can hold additional implementation-specific information. Some
example situations for each trigger value include:

- `internal_error`: not initialized, out of memory
- `rejected`: limits reached, DDoS protection, unwilling to track more paths
- `unsupported`: unknown or unsupported version
- `invalid`: packet parsing or validation error
- `duplicate`: duplicate packet
- `connection_unknown`: packet does not relate to a known connection or
  connection ID
- `decryption_failure`: decryption failed
- `key_unavailable`: decryption key was unavailable
- `general`: situations not clearly covered in the other categories

Packets dropped as `unsupported` or `connection_unknown` often cannot be tied to
a connection; see {{handling-unknown-connections}}.

The `datagram_payload_checksum` field is described in {{packet-coalescing}}.

## packet_buffered {#quic-packetbuffered}

The `packet_buffered` event is emitted when a packet is buffered because it
cannot be processed yet, for example because the keys to decrypt it are not
yet available. Its full contents can be logged later, in a `packet_received`
event, once it is processed. It has Base importance level.

~~~ cddl
QUICPacketBuffered = {

    ; primarily packet_type should be filled here as other elements
    ; might not be available yet
    ? header: PacketHeader
    ? raw: RawInfo
    ? datagram_payload_checksum: uint32
    ? trigger:
        ; indicates the parser cannot keep up, temporarily buffers
        ; packet for later processing
        "backpressure" /
        ; if packet cannot be decrypted because the proper keys were
        ; not yet available
        "keys_unavailable"

    * $$quic-packetbuffered-extension
}
~~~
{: #quic-packetbuffered-def title="QUICPacketBuffered definition"}

The `datagram_payload_checksum` field is described in {{packet-coalescing}}.

## packets_acked {#quic-packetsacked}

The `packets_acked` event is emitted when one or more sent packets are
acknowledged by the peer for the first time. It has Extra importance level.

Successive ACK frames can acknowledge the same packet, but this event is
emitted only for the first acknowledgment of each packet. This information can
also be deduced from received ACK frames, though finding the first
acknowledgment needs extra processing. Implementations that do not log frame
contents can use this event instead.

~~~ cddl
QUICPacketsAcked = {
    ? packet_number_space: $PacketNumberSpace
    ? packet_numbers: [+ uint64]

    * $$quic-packetsacked-extension
}
~~~
{: #quic-packetsacked-def title="QUICPacketsAcked definition"}

If `packet_number_space` is omitted, its value is `application_data`, the
packet number space that most packets in a typical QUIC connection use.

## udp_datagrams_sent {#quic-udpdatagramssent}

The `udp_datagrams_sent` event indicates that one or more UDP datagrams were
passed to the network socket. It can show how QUIC packet buffers are drained
to the operating system. It has Extra importance level.

~~~ cddl
QUICUDPDatagramsSent = {

    ; to support passing multiple at once
    ? count: uint16

    ; The RawInfo fields do not include the UDP headers,
    ; only the UDP payload
    ? raw: [+ RawInfo]

    ; ECN bits in the IP header
    ; if not set, defaults to the value used on the last
    ; QUICUDPDatagramsSent event
    ? ecn: [+ ECN]

    ? datagram_payload_checksums: [+ uint32]

    * $$quic-udpdatagramssent-extension
}
~~~
{: #quic-udpdatagramssent-def title="QUICUDPDatagramsSent definition"}

The RawInfo fields exclude UDP headers, because QUIC implementations do not
always handle UDP directly.

The `datagram_payload_checksums` field is described in {{packet-coalescing}}.

## udp_datagrams_received {#quic-udpdatagramsreceived}

The `udp_datagrams_received` event indicates that one or more UDP datagrams
were received from the network socket. It can show how the operating system
passes datagrams to the user-space stack. It has Extra importance level.

~~~ cddl
QUICUDPDatagramsReceived = {

    ; to support passing multiple at once
    ? count: uint16

    ; The RawInfo fields do not include the UDP headers,
    ; only the UDP payload
    ? raw: [+ RawInfo]

    ; ECN bits in the IP header
    ; if not set, defaults to the value on the last
    ; QUICUDPDatagramsReceived event
    ? ecn: [+ ECN]

    ? datagram_payload_checksums: [+ uint32]

    * $$quic-udpdatagramsreceived-extension
}
~~~
{: #quic-udpdatagramsreceived-def title="QUICUDPDatagramsReceived definition"}

The `datagram_payload_checksums` field is described in {{packet-coalescing}}.

## udp_datagram_dropped {#quic-udpdatagramdropped}

The `udp_datagram_dropped` event indicates that a UDP datagram was dropped,
typically because it does not contain a valid QUIC packet. If the datagram
contains a valid QUIC packet that is dropped for another reason, the
`packet_dropped` event ({{quic-packetdropped}}) is used instead. It has Extra
importance level.

~~~ cddl
QUICUDPDatagramDropped = {

    ; The RawInfo fields do not include the UDP headers,
    ; only the UDP payload
    ? raw: RawInfo

    * $$quic-udpdatagramdropped-extension
}
~~~
{: #quic-udpdatagramdropped-def title="QUICUDPDatagramDropped definition"}

## stream_state_updated {#quic-streamstateupdated}

The `stream_state_updated` event is emitted when the state of a QUIC stream
changes; see {{Section 3 of QUIC-TRANSPORT}}. Most state changes can be
inferred from the frames that are sent and received, but an explicit event can
be easier to use. It has Base importance level.

QUIC stream IDs encode whether a stream is unidirectional or bidirectional
(see {{Section 2.1 of QUIC-TRANSPORT}}), but the optional `stream_type` field
states it directly.

{{Section 3 of QUIC-TRANSPORT}} describes the sending and receiving parts of a
stream, each with its own state machine. The `stream_side` field says which
part's state changed. If both parts change state at the same time, for example
when both become `closed`, two events with different `stream_side` values
SHOULD be logged.

~~~ cddl
StreamType = "unidirectional" /
             "bidirectional"

QUICStreamStateUpdated = {
    stream_id: uint64
    ? stream_type: StreamType
    ? old: $StreamState
    new: $StreamState
    stream_side: "sending" /
                 "receiving"
    ? trigger:
      ; stream state change was initiated by a local action
      "local" /
      ; stream state change was initiated by a remote action
      "remote"

    * $$quic-streamstateupdated-extension
}

BaseStreamStates =  "idle" /
                    "open" /
                    "closed"

GranularStreamStates =
    ; bidirectional stream states, RFC 9000 Section 3.4.
    "half_closed_local" /
    "half_closed_remote" /
    ; sending-side stream states, RFC 9000 Section 3.1.
    "ready" /
    "send" /
    "data_sent" /
    "reset_sent" /
    ; receive-side stream states, RFC 9000 Section 3.2.
    "receive" /
    "size_known" /
    "data_read" /
    "reset_read" /
    ; both-side states
    "data_received" /
    "reset_received" /
    ; qlog-defined: memory actually freed
    "destroyed"

$StreamState /= BaseStreamStates / GranularStreamStates
~~~
{: #quic-streamstateupdated-def title="QUICStreamStateUpdated definition"}

QUIC implementations SHOULD log the BaseStreamStates, and can add the
GranularStreamStates when more in-depth debugging is required. Tools SHOULD
handle both kinds equally.

The `trigger` field can show which endpoint initiated a state change, for
example when a stream is closed because of a RESET_STREAM or STOP_SENDING
frame.

## Frame-related events

While the `packet_sent` ({{quic-packetsent}}) and `packet_received`
({{quic-packetreceived}}) events can convey all frames contained in a single
QUIC packet, some implementations might not be able or willing to include frame
information at the moment either event is logged.

The `frames_created` and `frames_parsed` events log frames independently of
packets.

A qlog trace can contain both packet- and frame-related events. However, it is
RECOMMENDED that implementations avoid generating events with duplicate or
redundant frame information, since doing so inflates the size of logs.

Where an implementation logs both packet- and frame-related events, the
optional `packet_numbers` field in frame-related events can be used to link
frames to packets explicitly. The field is an array so that a single event can
log frames that belong to different packets. The `frames` and `packet_numbers`
arrays are mapped to each other by the position and order of their entries. If
the `packet_numbers` field is logged, every frame MUST have a corresponding
packet number at the same index.

For example, an instance of the `frames_parsed` event that represents four
STREAM frames received over two packets can be serialized as:

~~~
"frames":[
  {"frame_type":"stream","stream_id":0,"offset":0,"raw":{"length":5}},
  {"frame_type":"stream","stream_id":0,"offset":5,"raw":{"length":5}},
  {"frame_type":"stream","stream_id":1,"offset":0,"raw":{"length":9}},
  {"frame_type":"stream","stream_id":1,"offset":9,"raw":{"length":9}}
],
"packet_numbers":[
  1,
  1,
  2,
  2
]
~~~

Frame-related events omit information that is available in the
`packet_received` or `packet_sent` event, such as the packet's encryption
level. Use cases that need such information are better served by those events.

Extensions can use frame-related events to log information that is not
available when a packet event is logged, for example because frame processing
was deferred.

### frames_created {#quic-framescreated}

The `frames_created` event indicates that a set of QUIC frames was created. It
has Extra importance level.

~~~ cddl
QUICFramesCreated = {
    frames: [* $QuicFrame]
    ? packet_numbers: [* uint64]

    * $$quic-framescreated-extension
}
~~~
{: #quic-framescreated-def title="QUICFramesCreated definition"}


### frames_parsed {#quic-framesparsed}

The `frames_parsed` event indicates that a set of QUIC frames was parsed. It has
Extra importance level.

~~~ cddl
QUICFramesParsed = {
    frames: [* $QuicFrame]
    ? packet_numbers: [* uint64]

    * $$quic-framesparsed-extension
}
~~~
{: #quic-framesparsed-def title="QUICFramesParsed definition"}

## stream_data_moved {#quic-streamdatamoved}

The `stream_data_moved` event indicates that QUIC stream data moved between
layers. It has Base importance level.

For example, data can move from an application protocol such as HTTP/3 to QUIC
stream buffers, or the other way. Logging these moves can show the flow of
data, how long data stays in each buffer, and the overhead introduced by each
layer.

This event can also show whether received stream data is passed to the
application protocol immediately or in batches. Data can be passed, for
example, once per received packet, or in a batch after all received packets
are processed. This can help identify bottlenecks, flow control issues, or
scheduling problems.

The `raw.length` field gives the number of bytes moved. Because this event
covers stream data only, there are no packet or frame headers, and
`raw.length` MUST reflect that.

The `additional_info` field can log information about the stream state. For
example, an application that moves data into the transport and ends the stream
at the same time can log `fin_set`. A transport that has received an
instruction to reset a stream can tell the application with `stream_reset`. In
both cases, `raw.length` can be omitted or be zero.

This event covers only data in QUIC streams. For data in QUIC datagrams, see
the `datagram_data_moved` event ({{quic-datagramdatamoved}}).

~~~ cddl
QUICStreamDataMoved = {
    ? stream_id: uint64
    ? offset: uint64

    ? from: $DataLocation
    ? to: $DataLocation

    ? additional_info: $DataMovedAdditionalInfo

    ? raw: RawInfo

    * $$quic-streamdatamoved-extension
}

$DataLocation /=  "application" /
                  "transport" /
                  "network"

$DataMovedAdditionalInfo /= "fin_set" /
                            "stream_reset"
~~~
{: #quic-streamdatamoved-def title="QUICStreamDataMoved definition"}

## datagram_data_moved {#quic-datagramdatamoved}

The `datagram_data_moved` event indicates that QUIC datagram data (see
{{QUIC-DATAGRAM}}) moved between layers. It has Base importance level.

For example, data can move from an application protocol such as WebTransport to
QUIC buffers, or the other way. Logging these moves can show the flow of data,
how long data stays in each buffer, and the overhead introduced by each layer.

This event can also show whether received datagram data is passed to the
application protocol immediately or in batches. Data can be passed, for
example, once per received packet, or in a batch after all received packets
are processed. This can help identify bottlenecks or scheduling problems.

The `raw.length` field gives the number of bytes moved. Because this event
covers datagram data only, there are no packet or frame headers, and
`raw.length` MUST reflect that.

This event covers only data in QUIC datagrams. For data in QUIC streams, see
the `stream_data_moved` event ({{quic-streamdatamoved}}).

~~~ cddl
QUICDatagramDataMoved = {
    ? from: $DataLocation
    ? to: $DataLocation
    ? raw: RawInfo

    * $$quic-datagramdatamoved-extension
}
~~~
{: #quic-datagramdatamoved-def title="QUICDatagramDataMoved definition"}

## connection_data_blocked_updated {#quic-connectiondatablockedupdated}

The `connection_data_blocked_updated` event indicates that the QUIC connection
became blocked or unblocked for sending data. It has Extra importance level.

Depending on the reason, a blocked connection cannot send stream data, datagram
data, or both, until that reason is resolved. The `stream_data_blocked_updated`
and `datagram_data_blocked_updated` events give more detail for each type of
data.

~~~ cddl
QUICConnectionDataBlockedUpdated = {
    ? old: $BlockedState
    new: $BlockedState

    ? reason: $BlockedReason
}

$BlockedState /= "blocked" /
               "unblocked"

$BlockedReason /= "scheduling" /
                  "pacing" /
                  "amplification_protection" /
                  "congestion_control" /
                  "connection_flow_control" /
                  "stream_flow_control" /
                  "stream_id" /
                  "application"
~~~
{: #quic-connectiondatablockedupdated-def title="QUICConnectionDataBlockedUpdated definition"}

## stream_data_blocked_updated {#quic-streamdatablockedupdated}

The `stream_data_blocked_updated` event indicates that a QUIC stream became
blocked or unblocked for sending. It has Extra importance level.

~~~ cddl
QUICStreamDataBlockedUpdated = {
    ? old: $BlockedState
    new: $BlockedState

    stream_id: uint64

    ? reason: $BlockedReason
}
~~~
{: #quic-streamdatablockedupdated-def title="QUICStreamDataBlockedUpdated definition"}

## datagram_data_blocked_updated {#quic-datagramdatablockedupdated}

The `datagram_data_blocked_updated` event indicates that QUIC datagrams became
blocked or unblocked for sending. It has Extra importance level.

~~~ cddl
QUICDatagramDataBlockedUpdated = {
    ? old: $BlockedState
    new: $BlockedState

    ? reason: $BlockedReason
}
~~~
{: #quic-datagramdatablockedupdated-def title="QUICDatagramDataBlockedUpdated definition"}

## migration_state_updated {#quic-migrationstateupdated}

The `migration_state_updated` event logs the progress of a connection migration
by a client; see {{Section 9 of QUIC-TRANSPORT}}. It has Extra importance level.

Most details of a migration can be inferred from PATH_CHALLENGE and
PATH_RESPONSE frames, together with `tuple_assigned` events. However, it can
be useful to log the progress of the migration, and any decisions made, in a
single event.

The MigrationState values follow the steps in {{Section 9 of QUIC-TRANSPORT}}:
the `probing_*` values cover probing a new path ({{Section 9.1 of
QUIC-TRANSPORT}}), and the `migration_*` values cover migrating the connection
({{Section 9.2 of QUIC-TRANSPORT}}).

Implementations that log per-path information in `migration_state_updated`
events SHOULD also emit `tuple_assigned` events, to serve as the ground truth
for tuple information.

~~~ cddl
QUICMigrationStateUpdated = {
    ? old: MigrationState
    new: MigrationState

    ? tuple_id: TupleID

    ; the information for traffic going towards the remote receiver
    ? tuple_remote: TupleEndpointInfo

    ; the information for traffic coming in at the local endpoint
    ? tuple_local: TupleEndpointInfo

    * $$quic-migrationstateupdated-extension
}

; Note that MigrationState does not describe a full state machine
; These entries are not necessarily chronological,
; nor will they always all appear during
; a connection migration attempt.
MigrationState =
    ; probing packets are sent, migration not initiated yet
    "probing_started" /
    ; did not get reply to probing packets,
    ; discarding path as an option
    "probing_abandoned" /
    ; received reply to probing packets, path is migration candidate
    "probing_successful" /
    ; non-probing packets are sent, attempting migration
    "migration_started" /
    ; something went wrong during the migration, abandoning attempt
    "migration_abandoned" /
    ; new path is now fully used, old path is discarded
    "migration_complete"
~~~
{: #quic-migrationstateupdated-def title="QUICMigrationStateUpdated definition"}


## timer_updated {#quic-timerupdated}

The `timer_updated` event is emitted when a timer changes state. It has Extra
importance level.

The `event_type` field takes one of three values:

* `set`: the timer is set, and `delta` gives the time until it triggers
* `expired`: the timer expired
* `cancelled`: the timer was cancelled

An update to an active timer's timeout is logged as a new `set` event.

The recovery timer types correspond to timers in {{Section 6 of
QUIC-RECOVERY}} and {{Appendix A.8 of QUIC-RECOVERY}}:

* `ack`: the time threshold loss detection timeout
* `pto`: the probe timeout
* `loss_timeout`: the single, multi-modal loss detection timer that covers
  both

QUIC uses a variety of timers, and how they are used can depend on the
implementation. Implementers can add fields to this event through
`$$quic-timerupdated-extension`, or add timer types through `$TimerType`.

~~~ cddl
; a non-exhaustive list of typically employed timers
$TimerType /= "ack" /
              "pto" /
              "loss_timeout" /
              "path_validation" /
              "handshake_timeout" /
              "idle_timeout"

QUICTimerUpdated = {
    ? timer_type: $TimerType

    ; to disambiguate in case there are multiple timers
    ; of the same type
    ? timer_id: uint64

    ; if used for recovery timers, this can be useful information
    ? packet_number_space: $PacketNumberSpace
    event_type: "set" /
                "expired" /
                "cancelled"

    ; if event_type === "set": delta time is in ms from
    ; this event's timestamp until when the timer should trigger
    ? delta: float32

    * $$quic-timerupdated-extension
}
~~~
{: #quic-timerupdated-def title="QUICTimerUpdated definition"}

# Security Events {#sec-ev}

## key_updated {#quic-keyupdated}

The `key_updated` event indicates that a key was installed or updated. It has
Base importance level.

This happens when TLS provides new keys during the handshake, and at each 1-RTT
key update; see {{Section 6 of QUIC-TLS}}.

~~~ cddl
QUICKeyUpdated = {
    key_type: $KeyType
    ? old: hexstring
    ? new: hexstring

    ; needed for 1RTT key updates
    ? key_phase: uint64
    ? trigger:
        ; (e.g., initial, handshake and 0-RTT keys
        ; are generated by TLS)
        "tls" /
        "remote_update" /
        "local_update"

    * $$quic-keyupdated-extension
}
~~~
{: #quic-keyupdated-def title="QUICKeyUpdated definition"}

The `key_phase` field holds the full key phase, which identifies the
generation of keys; it corresponds to @M and @N in Figure 9 of {{Section 6 of
QUIC-TLS}}. The Key Phase bit in the packet header is the least significant
bit of this value.

## key_discarded {#quic-keydiscarded}

The `key_discarded` event indicates that a key was discarded. It has Base
importance level.

Keys are discarded, for example, when the connection moves to a new encryption
level during the handshake, or after a key update; see {{Section 4.9 of
QUIC-TLS}}.

~~~ cddl
QUICKeyDiscarded = {
    key_type: $KeyType
    ? key: hexstring

    ; needed for 1RTT key updates
    ? key_phase: uint64
    ? trigger:
        ; (e.g., initial, handshake and 0-RTT keys
        ; are generated by TLS)
        "tls" /
        "remote_update" /
        "local_update"

    * $$quic-keydiscarded-extension
}
~~~
{: #quic-keydiscarded-def title="QUICKeyDiscarded definition"}

# Recovery events {#rec-ev}

Most of the events in this section are kept generic to support different
recovery approaches and congestion control algorithms. The `old`, `new`, and
`trigger` fields of `congestion_state_updated`, for instance, are free text, so
their values depend on the algorithm.

Tools that process these events SHOULD try to handle such values even when they
don't recognize them. For example, a tool that plots congestion states on a
timeline can label an unknown state with the value of the `new` field.

## recovery_parameters_set {#quic-recoveryparametersset}

The `recovery_parameters_set` event groups initial parameters from both loss
detection and congestion control into a single event. It has Base importance
level.

These parameters are typically set once and never change. Implementations that
change them during the connection MAY emit the `recovery_parameters_set` event
more than once.

The `reordering_threshold` field contains the packet threshold for loss detection,
or `"disabled"` if packet-threshold loss detection is disabled.

~~~ cddl
QUICRecoveryParametersSet = {

    ; Loss detection, see RFC 9002 Appendix A.2
    ; in amount of packets
    ? reordering_threshold: uint16 / "disabled"

    ; as RTT multiplier
    ? time_threshold: float32

    ; in ms
    timer_granularity: uint16

    ; in ms
    ? initial_rtt:float32

    ; congestion control, see RFC 9002 Appendix B.2
    ; in bytes. Note that this could be updated after pmtud
    ? max_datagram_size: uint32

    ; in bytes
    ? initial_congestion_window: uint64

    ; Note that this could change when max_datagram_size changes
    ; in bytes
    ? minimum_congestion_window: uint64
    ? loss_reduction_factor: float32

    ; as PTO multiplier
    ? persistent_congestion_threshold: uint16

    * $$quic-recoveryparametersset-extension
}
~~~
{: #quic-recoveryparametersset-def title="QUICRecoveryParametersSet definition"}

Parameters that this document does not define, such as those of other loss
detection and recovery algorithms, can be added through
`$$quic-recoveryparametersset-extension`.

## recovery_metrics_updated {#quic-recoverymetricsupdated}

The `recovery_metrics_updated` event is emitted when one or more of the
observable recovery metrics change value. It has Core importance level.

Implementations SHOULD group all metric updates that happen at or around the
same time into a single `recovery_metrics_updated` event. For example, if
`min_rtt` and `smoothed_rtt` change at the same time, they are logged in one
event, not two. Each event is only guaranteed to contain at least one of the
listed metrics.

~~~ cddl
QUICRecoveryMetricsUpdated = {

    ; Loss detection, see RFC 9002 Appendix A.3
    ; all following rtt fields are expressed in ms
    ? min_rtt: float32
    ? smoothed_rtt: float32
    ? latest_rtt: float32
    ? rtt_variance: float32
    ? pto_count: uint16

    ; Congestion control, see RFC 9002 Appendix B.2.
    ; in bytes
    ? congestion_window: uint64
    ? bytes_in_flight: uint64

    ; in bytes
    ? ssthresh: uint64

    ; qlog defined
    ; sum of all packet number spaces
    ? packets_in_flight: uint64

    ; in bits per second
    ? pacing_rate: uint64

    * $$quic-recoverymetricsupdated-extension
}
~~~
{: #quic-recoverymetricsupdated-def title="QUICRecoveryMetricsUpdated definition"}

To make logging easier, implementations MAY log values that are the same as
previously reported values; for example, two consecutive
`recovery_metrics_updated` events can report the same `min_rtt`. However,
implementations SHOULD try to log only values that changed.

Metrics that this document does not define, such as those of other loss
detection and recovery algorithms, can be added through
`$$quic-recoverymetricsupdated-extension`.

## congestion_state_updated {#quic-congestionstateupdated}

The `congestion_state_updated` event indicates when the congestion controller
enters a significant new state and changes its behaviour. It has Base importance
level.

The values of the event's fields are intentionally unspecified here in order to
support different Congestion Control algorithms, as these typically have
different states and even different implementations of these states across
stacks. For example, for the algorithm defined in the QUIC Recovery RFC
("enhanced" New Reno), the following states are used: Slow Start, Congestion
Avoidance, Application Limited and Recovery. Similarly, states can be triggered
by a variety of events, including detection of Persistent Congestion or receipt
of ECN markings.

~~~ cddl
QUICCongestionStateUpdated = {
    ? old: text
    new: text
    ? trigger: text

    * $$quic-congestionstateupdated-extension
}
~~~
{: #quic-congestionstateupdated-def title="QUICCongestionStateUpdated definition"}

The `trigger` field SHOULD be logged if there are multiple ways in which a state
change can occur but MAY be omitted if a given state can only be due to a single
event occurring (for example Slow Start is often exited only when ssthresh is
exceeded).

## packet_lost {#quic-packetlost}

The `packet_lost` event is emitted when a packet is deemed lost by loss
detection. It has Core importance level.

It is RECOMMENDED to populate the optional `trigger` field in order to help
disambiguate among the various possible causes of a loss declaration.

~~~ cddl
QUICPacketLost = {

    ; should include at least the packet_type and packet_number
    ? header: PacketHeader

    ; not all implementations will keep track of full
    ; packets, so these are optional
    ? frames: [* $QuicFrame]
    ? is_mtu_probe_packet: bool .default false
    ? trigger:
        "reordering_threshold" /
        "time_threshold" /
        ; RFC 9002 Section 6.2.4 paragraph 6, MAY
        "pto_expired"

    * $$quic-packetlost-extension
}
~~~
{: #quic-packetlost-def title="QUICPacketLost definition"}

## marked_for_retransmit {#quic-markedforretransmit}

The `marked_for_retransmit` event indicates which data was marked for
retransmission upon detection of packet loss (see `packet_lost`). It has Extra
importance level.

Similar to the reasoning for the `frames_sent` and `frames_parsed` events,
in order to keep the amount of different events low, this signal is grouped into
in a single event based on existing QUIC frame definitions for all types of
retransmittable data.

Implementations retransmitting full packets or frames directly can just log the
constituent frames of the lost packet here (or do away with this event and use the
contents of the `packet_lost` event instead). Conversely, implementations that have
more complex logic (e.g., marking ranges in a stream's data buffer as in-flight),
or that do not track sent frames in full (e.g., only stream offset + length), can
translate their internal behaviour into the appropriate frame instance here even
if that frame was never or will never be put on the wire.

Much of this data can be inferred if implementations log `packet_sent` events
(e.g., looking at overlapping stream data offsets and length, one can determine
when data was retransmitted).

~~~ cddl
QUICMarkedForRetransmit = {
    frames: [+ $QuicFrame]

    * $$quic-markedforretransmit-extension
}
~~~
{: #quic-markedforretransmit-def title="QUICMarkedForRetransmit definition"}

## ecn_state_updated {#quic-ecnstateupdated}

The `ecn_state_updated` event indicates a progression in the ECN state machine
as described in {{Appendix A.4 of QUIC-TRANSPORT}}. It has Extra importance
level.

~~~ cddl
QUICECNStateUpdated = {
   ? old: ECNState
    new: ECNState

    * $$quic-ecnstateupdated-extension
}

ECNState =
  ; ECN testing in progress
  "testing" /
  ; ECN state unknown, waiting for acknowledgements
  ; for testing packets
  "unknown" /
  ; ECN testing failed
  "failed" /
  ; testing was successful
  "capable"
~~~
{: #quic-ecnstateupdated-def title="QUICECNStateUpdated definition"}


# QUIC data type definitions {#quic-data-types}

## QuicVersion

~~~ cddl
QuicVersion = hexstring
~~~
{: #quicversion-def title="QuicVersion definition"}

## ConnectionID

~~~ cddl
ConnectionID = hexstring
~~~
{: #connectionid-def title="ConnectionID definition"}

## Initiator

~~~ cddl
Initiator = "local" /
            "remote"
~~~
{: #initiator-def title="Initiator definition"}

## IPAddress

~~~ cddl
; an IPAddress can either be a "human readable" form
; (e.g., "127.0.0.1" for v4 or
; "2001:0db8:85a3:0000:0000:8a2e:0370:7334" for v6) or
; use a raw byte-form (as the string forms can be ambiguous).
; Additionally, a hash-based or redacted representation
; can be used if needed for privacy or security reasons.
IPAddress = text /
            hexstring
~~~
{: #ipaddress-def title="IPAddress definition"}

## TupleEndpointInfo

TupleEndpointInfo indicates a single half/direction of a four-tuple. A full tuple
is comprised of two halves. Firstly: the server sends to the remote client IP
+ port using a specific destination Connection ID. Secondly: the client sends to
the remote server IP + port using a different destination Connection ID.

As such, structures logging tuple information SHOULD include two different
TupleEndpointInfo instances, one for each half of the tuple.

~~~ cddl
TupleEndpointInfo = {
    ? ip_v4: IPAddress
    ? port_v4: uint16
    ? ip_v6: IPAddress
    ? port_v6: uint16

    ; Even though usually only a single ConnectionID
    ; is associated with a given tuple/path at a time,
    ; there are situations where there can be an overlap
    ; or a need to keep track of previous ConnectionIDs
    ? connection_ids: [+ ConnectionID]

    * $$quic-tupleendpointinfo-extension
}
~~~
{: #tupleendpointinfo-def title="TupleEndpointInfo definition"}

## PacketType

~~~ cddl
$PacketType /=  "initial" /
                "handshake" /
                "0RTT" /
                "1RTT" /
                "retry" /
                "version_negotiation" /
                "stateless_reset" /
                "unknown"
~~~
{: #packettype-def title="PacketType definition"}

## PacketNumberSpace

~~~ cddl
$PacketNumberSpace /= "initial" /
                      "handshake" /
                      "application_data"
~~~
{: #packetnumberspace-def title="PacketNumberSpace definition"}

## PacketHeader

If the `packet_type` numerical value does not map to a known `$PacketType`
string, the `packet_type` value of "unknown" can be used and the raw value
captured in the `packet_type_bytes` field; a numerical value without
variable-length integer encoding.

PacketHeader omits the fixed bit and the reserved bits because QUIC version 1
gives them fixed values; see {{Section 17 of QUIC-TRANSPORT}}. Their values can
be logged in the `raw.data` field of the event that logs the PacketHeader.

QUIC extensions that do utilize these bits are expected to create new events
(analogous to `spin_bit_updated`) or use qlog extension mechanisms to reflect
that usage.

For long header packets of type initial, handshake, and 0RTT, the length field
of the packet header is logged in the qlog `raw.length` field, and the value
signifies the length of the packet number plus the payload.

~~~ cddl
PacketHeader = {
    packet_type: $PacketType

    ; only if packet_type === "unknown"
    ? packet_type_bytes: uint64

    ; only if packet_type === "1RTT"
    ? spin_bit: bool

    ; only if packet_type === "1RTT", and if the key phase was
    ; determined from the key_phase_bit
    ? key_phase: uint64

    ; only if packet_type === "1RTT", and if key_phase is not set
    ? key_phase_bit: bool

    ; only if packet_type === "initial" || "handshake" || "0RTT" ||
    ;                         "1RTT"
    ? packet_number_length: uint8

    ; only if packet_type === "initial" || "handshake" || "0RTT" ||
    ;                         "1RTT"
    ? packet_number: uint64

    ; only if packet_type === "initial" || "retry"
    ? token: Token

    ; only if packet_type === "initial" || "handshake" || "0RTT"
    ; Signifies length of the packet_number plus the payload
    ? length: uint16

    ; only if present in the header.
    ; if correctly using connection_id_updated events,
    ; dcid can be skipped for 1RTT packets
    ? version: QuicVersion
    ? scil: uint8
    ? dcil: uint8
    ? scid: ConnectionID
    ? dcid: ConnectionID

    * $$quic-packetheader-extension
}
~~~
{: #packetheader-def title="PacketHeader definition"}

## Token

~~~ cddl
Token = {
    ? type: $TokenType

    ; decoded fields included in the token
    ; (typically: peer's IP address, creation time)
    ? details: {
      * text => any
    }
    ? raw: RawInfo

    * $$quic-token-extension
}

$TokenType /= "retry" /
              "resumption"
~~~
{: #token-def title="Token definition"}

The token carried in an Initial packet can either be a retry token from a Retry
packet, or one originally provided by the server in a NEW_TOKEN frame used when
resuming a connection (e.g., for address validation purposes). Retry and
resumption tokens typically contain encoded metadata to check the token's
validity when it is used, but this metadata and its format is implementation
specific. For that, `Token` includes a general-purpose `details` field.

## Stateless Reset Token

~~~ cddl
StatelessResetToken = hexstring .size 16
~~~
{: #stateless-reset-token-def title="Stateless Reset Token definition"}

The stateless reset token is carried in stateless reset packets, in transport
parameters and in NEW_CONNECTION_ID frames.

## KeyType

~~~ cddl
$KeyType /= "server_initial_secret" /
            "client_initial_secret" /
            "server_handshake_secret" /
            "client_handshake_secret" /
            "server_0rtt_secret" /
            "client_0rtt_secret" /
            "server_1rtt_secret" /
            "client_1rtt_secret"
~~~
{: #keytype-def title="KeyType definition"}

## ECN
~~~ cddl
ECN = "Not-ECT" / "ECT(1)" / "ECT(0)" / "CE"
~~~
{: #ecn-def title="ECN definition"}

The ECN bits carried in the IP header.

## QUIC Frames

The generic `$QuicFrame` is defined here as a CDDL "type socket" extension
point. It can be extended to support additional QUIC frame types.

~~~~~~
; The QuicFrame is any key-value map (e.g., JSON object)
$QuicFrame /= {
    * text => any
}
~~~~~~
{: #quicframe-def title="QuicFrame type socket definition"}

The QUIC frame types defined in this document are as follows:

~~~ cddl
QuicBaseFrames =  PaddingFrame /
                  PingFrame /
                  AckFrame /
                  ResetStreamFrame /
                  ResetStreamAtFrame /
                  StopSendingFrame /
                  CryptoFrame /
                  NewTokenFrame /
                  StreamFrame /
                  MaxDataFrame /
                  MaxStreamDataFrame /
                  MaxStreamsFrame /
                  DataBlockedFrame /
                  StreamDataBlockedFrame /
                  StreamsBlockedFrame /
                  NewConnectionIDFrame /
                  RetireConnectionIDFrame /
                  PathChallengeFrame /
                  PathResponseFrame /
                  ConnectionCloseFrame /
                  HandshakeDoneFrame /
                  UnknownFrame /
                  DatagramFrame

$QuicFrame /= QuicBaseFrames
~~~
{: #quicbaseframe-def title="QuicBaseFrames definition"}

### PaddingFrame

In QUIC, PADDING frames are simply identified as a single byte of value 0. As
such, each padding byte could be theoretically interpreted and logged as an
individual PaddingFrame.

However, as this leads to heavy logging overhead, implementations SHOULD instead
emit just a single PaddingFrame and set the `raw.payload_length` property to the
amount of PADDING bytes/frames included in the packet.

~~~ cddl
PaddingFrame = {
    frame_type: "padding"
    ? raw: RawInfo
}
~~~
{: #paddingframe-def title="PaddingFrame definition"}

### PingFrame

~~~ cddl
PingFrame = {
    frame_type: "ping"
    ? raw: RawInfo
}
~~~
{: #pingframe-def title="PingFrame definition"}

### AckFrame

~~~ cddl
; either a single number (e.g., [1]) or two numbers (e.g., [1,2]).
; For two numbers:
; the first number is "from": lowest packet number in interval
; the second number is "to": up to and including the highest
; packet number in the interval
AckRange = [1*2 uint64]

AckFrame = {
    frame_type: "ack"

    ; in ms
    ? ack_delay: float32

    ; e.g., looks like [[1,2],[4,5], [7], [10,22]] serialized
    ? acked_ranges: [+ AckRange]

    ; ECN (explicit congestion notification) related fields
    ; (not always present)
    ? ect1: uint64
    ? ect0: uint64
    ? ce: uint64
    ? raw: RawInfo
}
~~~
{: #ackframe-def title="AckFrame definition"}

Note that the packet ranges in AckFrame.acked_ranges do not necessarily have to be
ordered (e.g., \[\[5,9\],\[1,4\]\] is a valid value).

Note that the two numbers in the packet range can be the same (e.g., \[120,120\] means
that packet with number 120 was ACKed). However, in that case, implementers SHOULD
log \[120\] instead and tools MUST be able to deal with both notations.

### ResetStreamFrame

If the error numerical value does not map to a known ApplicationError string,
the error value of "unknown" can be used and the raw value captured in the
error_code field; a numerical value without variable-length integer encoding.

~~~ cddl
ResetStreamFrame = {
    frame_type: "reset_stream"
    stream_id: uint64
    error: $ApplicationError

    ; if error === "unknown"
    ? error_code: uint64

    ; in bytes
    final_size: uint64
    ? raw: RawInfo
}
~~~
{: #resetstreamframe-def title="ResetStreamFrame definition"}

### ResetStreamAtFrame

If the error numerical value does not map to a known ApplicationError string,
the error value of "unknown" can be used and the raw value captured in the
error_code field; a numerical value without variable-length integer encoding.

~~~ cddl
ResetStreamAtFrame = {
    frame_type: "reset_stream_at"
    stream_id: uint64
    error: $ApplicationError

    ; if error === "unknown"
    ? error_code: uint64

    ; in bytes
    final_size: uint64

    ; in bytes
    reliable_size: uint64

    ? raw: RawInfo
}
~~~
{: #resetstreamatframe-def title="ResetStreamAtFrame definition"}


### StopSendingFrame

If the error numerical value does not map to a known ApplicationError string,
the error value of "unknown" can be used and the raw value captured in the
error_code field; a numerical value without variable-length integer encoding.

~~~ cddl
StopSendingFrame = {
    frame_type: "stop_sending"
    stream_id: uint64
    error: $ApplicationError

    ; if error === "unknown"
    ? error_code: uint64

    ? raw: RawInfo
}
~~~
{: #stopsendingframe-def title="StopSendingFrame definition"}

### CryptoFrame

The length field of the Crypto frame MUST be logged in the qlog `raw.length`
field. The other sub-fields of the `raw` field are optional.

~~~ cddl
CryptoFrame = {
    frame_type: "crypto"
    offset: uint64
    raw: RawInfo
}
~~~
{: #cryptoframe-def title="CryptoFrame definition"}

### NewTokenFrame

~~~ cddl
NewTokenFrame = {
  frame_type: "new_token"
  token: Token
  ? raw: RawInfo
}
~~~
{: #newtokenframe-def title="NewTokenFrame definition"}

### StreamFrame

If the stream frame contains a length field, it MUST be logged in the qlog
`raw.length` field. If it does not, the implementation MAY calculate the actual
frame byte length itself and log that in `raw.length` if necessary.

~~~ cddl
StreamFrame = {
    frame_type: "stream"
    stream_id: uint64
    ? offset: uint64 .default 0
    ? fin: bool .default false
    ? raw: RawInfo
}
~~~
{: #streamframe-def title="StreamFrame definition"}

### MaxDataFrame

~~~ cddl
MaxDataFrame = {
  frame_type: "max_data"
  maximum: uint64
  ? raw: RawInfo
}
~~~
{: #maxdataframe-def title="MaxDataFrame definition"}

### MaxStreamDataFrame

~~~ cddl
MaxStreamDataFrame = {
  frame_type: "max_stream_data"
  stream_id: uint64
  maximum: uint64
  ? raw: RawInfo
}
~~~
{: #maxstreamdataframe-def title="MaxStreamDataFrame definition"}

### MaxStreamsFrame

~~~ cddl
MaxStreamsFrame = {
  frame_type: "max_streams"
  stream_type: StreamType
  maximum: uint64
  ? raw: RawInfo
}
~~~
{: #maxstreamsframe-def title="MaxStreamsFrame definition"}

### DataBlockedFrame

~~~ cddl
DataBlockedFrame = {
  frame_type: "data_blocked"
  limit: uint64
  ? raw: RawInfo
}
~~~
{: #datablockedframe-def title="DataBlockedFrame definition"}

### StreamDataBlockedFrame

~~~ cddl
StreamDataBlockedFrame = {
  frame_type: "stream_data_blocked"
  stream_id: uint64
  limit: uint64
  ? raw: RawInfo
}
~~~
{: #streamdatablockedframe-def title="StreamDataBlockedFrame definition"}

### StreamsBlockedFrame

~~~ cddl
StreamsBlockedFrame = {
  frame_type: "streams_blocked"
  stream_type: StreamType
  limit: uint64
  ? raw: RawInfo
}
~~~
{: #streamsblockedframe-def title="StreamsBlockedFrame definition"}

### NewConnectionIDFrame

~~~ cddl
NewConnectionIDFrame = {
  frame_type: "new_connection_id"
  sequence_number: uint64
  retire_prior_to: uint64

  ; mainly used if e.g., for privacy reasons the full
  ; connection_id cannot be logged
  ? connection_id_length: uint8
  connection_id: ConnectionID
  ? stateless_reset_token: StatelessResetToken
  ? raw: RawInfo
}
~~~
{: #newconnectionidframe-def title="NewConnectionIDFrame definition"}

### RetireConnectionIDFrame

~~~ cddl
RetireConnectionIDFrame = {
  frame_type: "retire_connection_id"
  sequence_number: uint64
  ? raw: RawInfo
}
~~~
{: #retireconnectionid-def title="RetireConnectionIDFrame definition"}

### PathChallengeFrame

~~~ cddl
PathChallengeFrame = {
  frame_type: "path_challenge"

  ; always 64 bits
  ? data: hexstring
  ? raw: RawInfo
}
~~~
{: #pathchallengeframe-def title="PathChallengeFrame definition"}

### PathResponseFrame

~~~ cddl
PathResponseFrame = {
  frame_type: "path_response"

  ; always 64 bits
  ? data: hexstring
  ? raw: RawInfo
}
~~~
{: #pathresponseframe-def title="PathResponseFrame definition"}

### ConnectionCloseFrame

An endpoint that receives unknown error codes can record it in the error_code
field using the numerical value without variable-length integer encoding.

The `trigger_frame_type` field logs the Frame Type field, which only the
transport variant of CONNECTION_CLOSE (type 0x1c) carries; see {{Section 19.19
of QUIC-TRANSPORT}}. A known frame type is logged as its frame type string,
such as "stream". An unknown frame type is logged as the numerical value
without variable-length integer encoding.

The CONNECTION_CLOSE reason phrase is a byte sequence. It is likely that this
sequence is presentable as UTF-8, in which case it can be logged in the `reason`
field. The `reason_bytes` field supports logging the raw bytes, which can be useful
when the value is not UTF-8 or when an endpoint does not want to decode it.
Implementations SHOULD log at least one format, but MAY log both or none.

~~~ cddl
ErrorSpace = "transport" /
             "application"

ConnectionCloseFrame = {
    frame_type: "connection_close"
    ? error_space: ErrorSpace
    ? error: $TransportError / CryptoError /
             $ApplicationError

    ; if error === "unknown"
    ? error_code: uint64

    ? reason: text
    ? reason_bytes: hexstring

    ; when error_space === "transport"
    ? trigger_frame_type: uint64 /
                          text
    ? raw: RawInfo
}
~~~
{: #connectioncloseframe-def title="ConnectionCloseFrame definition"}

### HandshakeDoneFrame

~~~ cddl
HandshakeDoneFrame = {
  frame_type: "handshake_done"
  ? raw: RawInfo
}
~~~
{: #handshakedoneframe-def title="HandshakeDoneFrame definition"}

### UnknownFrame

The frame_type_bytes field is the numerical value without variable-length
integer encoding.

~~~ cddl
UnknownFrame = {
    frame_type: "unknown"
    frame_type_bytes: uint64
    ? raw: RawInfo
}
~~~
{: #unknownframe-def title="UnknownFrame definition"}

### DatagramFrame

The QUIC DATAGRAM frame is defined in {{Section 4 of !RFC9221}}.

If the datagram frame contains a length field, it MUST be logged in the qlog
`raw.length` field. If it does not, the implementation MAY calculate the actual
datagram byte length itself and log that in `raw.length` if necessary.

~~~ cddl
DatagramFrame = {
    frame_type: "datagram"
    ? raw: RawInfo
}
~~~
{: #datagramframe-def title="DatagramFrame definition"}

### TransportError

The generic `$TransportError` is defined here as a CDDL "type socket" extension
point. It can be extended to support additional Transport errors.

~~~ cddl
$TransportError /= "no_error" /
                 "internal_error" /
                 "connection_refused" /
                 "flow_control_error" /
                 "stream_limit_error" /
                 "stream_state_error" /
                 "final_size_error" /
                 "frame_encoding_error" /
                 "transport_parameter_error" /
                 "connection_id_limit_error" /
                 "protocol_violation" /
                 "invalid_token" /
                 "application_error" /
                 "crypto_buffer_exceeded" /
                 "key_update_error" /
                 "aead_limit_reached" /
                 "no_viable_path" /
                 "unknown"
                 ; there is no value to reflect CRYPTO_ERROR
                 ; use the CryptoError type instead
~~~
{: #transporterror-def title="TransportError definition"}

### ApplicationError

By definition, an application error is defined by the application-level
protocol running on top of QUIC (e.g., HTTP/3).

As such, it cannot be defined here completely. It is instead defined as a CDDL
"type socket" extension point, with a single "unknown" value.

~~~ cddl
$ApplicationError /= "unknown"
~~~
{: #applicationerror-def title="ApplicationError definition"}

Application-level qlog definitions that wish to define new ApplicationError
strings MUST do so by extending the $ApplicationError socket as such:

~~~~~~
$ApplicationError /= "new_error_name" /
                     "another_new_error_name"
~~~~~~

### CryptoError

These errors are defined in the TLS document as "A TLS alert is turned into a QUIC
connection error by converting the one-byte alert description into a QUIC error
code. The alert description is added to 0x100 to produce a QUIC error code from
the range reserved for CRYPTO_ERROR."

This approach maps badly to a pre-defined enum. As such, the crypto_error
string is defined as having a dynamic component here, which should include the
hex-encoded and zero-padded value of the TLS alert description.

~~~ cddl
; all strings from "crypto_error_0x100" to "crypto_error_0x1ff"
CryptoError = text .regexp "crypto_error_0x1[0-9a-f][0-9a-f]"
~~~
{: #cryptoerror-def title="CryptoError definition"}

# Handling Packet Coalescing {#packet-coalescing}

Multiple QUIC packets can be coalesced into a single UDP datagram, especially
during the handshake; see {{Section 12.2 of QUIC-TRANSPORT}}. Neither QUIC nor
UDP provides a way to tell which packets shared a datagram.

To let tools match QUIC packet events to UDP datagram events, the optional
`datagram_payload_checksum` field carries a 32-bit CRC32c of the UDP payload,
calculated as described in {{Section 11.3 of !RFC9868}}. The UDP datagram
events carry one checksum per datagram, in their `datagram_payload_checksums`
field.

# Security and Privacy Considerations

The security and privacy considerations discussed in {{Section 14 of QLOG-MAIN}} apply to this
document as well.

# IANA Considerations

This document registers a new entry in the "qlog event schema URIs" registry (created in {{Section 15 of QLOG-MAIN}}):

Event schema URI:
: urn:ietf:params:qlog:events:quic

Namespace
: quic

Event Types
: server_listening,
  connection_started,
  connection_closed,
  connection_id_updated,
  spin_bit_updated,
  connection_state_updated,
  tuple_assigned,
  mtu_updated,
  version_information,
  alpn_information,
  parameters_set,
  parameters_restored,
  packet_sent,
  packet_received,
  packet_dropped,
  packet_buffered,
  packets_acked,
  udp_datagrams_sent,
  udp_datagrams_received,
  udp_datagram_dropped,
  stream_state_updated,
  frames_created,
  frames_parsed,
  stream_data_moved,
  datagram_data_moved,
  connection_data_blocked_updated,
  stream_data_blocked_updated,
  datagram_data_blocked_updated,
  migration_state_updated,
  key_updated,
  key_discarded,
  recovery_parameters_set,
  recovery_metrics_updated,
  congestion_state_updated,
  timer_updated,
  packet_lost,
  marked_for_retransmit,
  ecn_state_updated

Description:
: Event definitions related to the QUIC transport protocol.

Reference:
: This Document

--- back

# Acknowledgements
{:numbered="false"}

Much of the initial work by Robin Marx was done at the Hasselt and KU Leuven
Universities.

Thanks to Jana Iyengar, Brian Trammell, Dmitri Tikhonov, Stephen Petrides, Jari
Arkko, Marcus Ihlar, Victor Vasiliev, Mirja Kühlewind, Jeremy Lainé, Kazu
Yamamoto, Christian Huitema, Hugo Landau, Will Hawkins, Mathis Engelbart, Kazuho
Oku, and Jonathan Lennox for their feedback and suggestions.

# Change Log
{:numbered="false" removeinrfc="true"}

## Since draft-ietf-qlog-quic-events-12:
{:numbered="false"}

* Split frames_processed into 3 events (#513)
* Wide range of editorial changes

## Since draft-ietf-qlog-quic-events-11:
{:numbered="false"}

* Updated several fields to be uint64 per QUIC spec
* Renamed error and error_code fields and logic (#473)
* Clarified parameters_set usage (#493)
* Replaced all length fields with raw.length (#495)
* Change loss_timer_updated to timer_updated (#496)
* Renamed path_assigned to tuple_assigned (#491)
* Reworked stream_state_updated (#497)
* Renamed owner to initiator (#498)
* Split up flags in PacketHeader (#478)

## Since draft-ietf-qlog-quic-events-09:
{:numbered="false"}

* Several editorial changes
* Reworked QUICConnectionStarted to use PathEndpointInfo (#453)
* Consistent use of RawInfo and _bytes fields to log raw data (#450)

## Since draft-ietf-qlog-quic-events-08:
{:numbered="false"}

* Removed individual categories and put every event in the single `quic` event
  schema namespace. Major change (#439)
* Renamed `recovery:metrics_updated` to `quic:recovery_metrics_updated` and
  `recovery:parameters_set` to `quic:recovery_parameters_set` (#439)
* Added `unknown_parameters` field to `parameters_set` (#438)
* Added extra parameters to `parameters_restored` (#441)

## Since draft-ietf-qlog-quic-events-07:
{:numbered="false"}

* TODO (we forgot...)

## Since draft-ietf-qlog-quic-events-06:
{:numbered="false"}

* Added PathAssigned and MigrationStateUpdated events (#336)
* Added extension points to parameters_set and parameters_restored (#400)
* Removed error_code_value from connection_closed (#386, #392)
* Renamed generation to key_phase for key_updated and key_discarded (#390)
* Removed retry_token from packet_sent and packet_received (#389)
* Updated ALPN handling (#385)
* Added key_unavailable trigger to packet_dropped (#381)
* Updated several uint32 to uint64
* ProtocolEventBody is now called ProtocolEventData (#352)
* Editorial changes (#402, #404, #394, #393)

## Since draft-ietf-qlog-quic-events-05:
{:numbered="false"}

* SecurityKeyUpdated: the new key is no longer mandatory to log (#294)
* Added ECN related events and metadata (#263)

## Since draft-ietf-qlog-quic-events-04:
{:numbered="false"}

* Updated guidance on logging events across connections (#279)
* Renamed 'transport' category to 'quic' (#302)
* Added support for multiple packet numbers in 'quic:frames_processed' (#307)
* Added definitions for RFC9287 (QUIC GREASE Bit extension) (#311)
* Added definitions for RFC9221 (QUIC Datagram Frame extension) (#310)
* (Temporarily) removed definitions for connection migration events (#317)
* Editorial and formatting changes (#298, #299, #304, #306, #327)

## Since draft-ietf-qlog-quic-events-03:
{:numbered="false"}

* Ensured consistent use of RawInfo to indicate raw wire bytes (#243)
* Renamed UnknownFrame:raw_frame_type to :frame_type_value (#54)
* Renamed ConnectionCloseFrame:raw_error_code to :error_code_value (#54)
* Changed triggers for packet_dropped (#278)
* Added entries to TransportError enum (#285)
* Changed minimum_congestion_window to uint64 (#288)

## Since draft-ietf-qlog-quic-events-02:
{:numbered="false"}

* Renamed key_retired to key_discarded (#185)
* Added fields and events for DPLPMTUD (#135)
* Made packet_number optional in PacketHeader (#244)
* Removed connection_retried event placeholder (#255)
* Changed QuicFrame to a CDDL plug type (#257)
* Moved data definitions out of the appendix into separate sections
* Added overview Table of Contents

## Since draft-ietf-qlog-quic-events-01:
{:numbered="false"}

* Added Stateless Reset Token type (#122)

## Since draft-ietf-qlog-quic-events-00:
{:numbered="false"}

* Change the data definition language from TypeScript to CDDL (#143)

## Since draft-marx-qlog-event-definitions-quic-h3-02:
{:numbered="false"}

* These changes were done in preparation of the adoption of the drafts by the QUIC
  working group (#137)
* Split QUIC and HTTP/3 events into two separate documents
* Moved RawInfo, Importance, Generic events and Simulation events to the main
  schema document.
* Changed to/from value options of the `data_moved` event

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
