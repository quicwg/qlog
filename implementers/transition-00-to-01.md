# Implementer's guide from draft-00 to draft-01

qlog draft-01 includes a number of impactful changes. 
This means implementers currently on draft-00 cannot simply add the new events in draft-01 and stay 01 compliant.
This document lists the compatibility-breaking changes and how to update qlogging to 01 if you currently have 00.

Note for implementers using the "editor's draft" version of 01 (prior to October 14th 2019):
While we will keep draft-00 support in our tools for a while, 
the "editor's draft" version of 01 has been substantially changed for the final 01, largely thanks to your experiences and inputs.
As such, our tools will NOT provide support for this older 01 version but only the final one published via the IETF. 
This guide will probably also be partly useful for you, since some use a frankenstein combination of -00 and -01 at this time.

For some, it might help to have something a bit more concrete.
A full TypeScript definition of the 01 schema can be found at: https://github.com/quiclog/qlog/blob/master/TypeScript/draft-01/QLog.ts

A full changelist from "editor's draft 01" to "final 01" is in this commit: https://github.com/quiclog/qlog/commit/e2784ab577ddc8f4ba1f8311a13601a51a179656 

# General

## lowercase all the things

**Everything** is now lower-cased. Previously, event_fields were CATEGORY, EVENT, DATA. Now, they are category, event, data, etc.

This also includes:
- vantage_point names (e.g., SERVER to server, CLIENT to client)
- specific category names (e.g., TRANSPORT is now transport, RECOVERY is recovery)
- specific event names (e.g., PACKET_SENT is now packet_sent)
- trigger values
- error names
- frame types (e.g., ACK is now ack, STREAM is now stream)

## The trigger field is now an optional field as part of the data

Since few people were using triggers and many events do not have (m)any discernable triggers, we decided to add it as a top-level option to the "data" field instead.

If you were using triggers as separate fields (e.g., mentioned them in "event_fields" and logged their values separately per-event), you should remove "trigger" from "event_fields" and instead add a "trigger" property to your data. For an example, see the main-schema-draft-01 document.

## group_ids is renamed to group_id

I am unaware of anyone using this method at this time, but added here for completeness. 

If you were logging multiple connections in a given trace and using the "index-based reference" method of group_ids, you have to rename the "group_ids" field in "common_fields" to simply read "group_id". 

## Option to use the .well-known URI

There is now a .well-known URI specified that you can use to make logs available on. While there are many arguments against such a setup when actually deploying implementations to production, adopting this URI would make automated testing and filling out the interop sheets much easier. Right now, everyone uses their own way of hosting and making available logs, this is an attempt to make this more consistent, at least during interops.

The URI is: **.well-known/log/{ODCID}**

So for example: https://quic.aiortc.org/.well-known/log/e5ed052f6c07cf96

## vantage_point is now required

Previously, the vantage_point field was not required per trace and several implementations do not set it or not correctly. Since many tools really rely on the vantage_point being correctly set, this is now a required field.

# Specific events

Next to the addition of many new events, some of the events defined in 00 have changes names or have been replaced by other events.

## Name changes

To make event names more consistent and reflect their purpose better, several events have changes names. Note especially the use of the past tense when using verbs (e.g., _update becomes _update**d**).

The data for each of these events has remained relatively stable, but most have 1 or 2 changed fields which should be taken into account. See below.

- CONNECTION_NEW -> connection_started
- CONNECTION_ID_UPDATE -> connection_id_updated
- KEY_UPDATE -> key_updated
- KEY_RETIRE -> key_retired
- PACKET_DROPPED -> packet_dropped
- STREAM_STATE_UPDATE -> stream_state_updated
- METRIC_UPDATE -> metrics_updated
- CC_STATE_UPDATE -> congestion_state_updated
- LOSS_ALARM_SET -> loss_timer_set
- LOSS_ALARM_FIRED -> loss_timer_expired

## Event semantics changes

These events have been removed or merged with others into new events. 

- CONNECTION_CLOSED -> instead use connectivity.connection_state_updated
- HEADER_DECRYPT_ERROR + HEADER_ENCRYPT_ERROR -> instead use error.connection_error
- CIPHER_UPDATE + VERSION_UPDATE + TRANSPORT_PARAMETERS_UPDATE + ALPN_UPDATE -> instead use transport.parameters_set
- FLOW_CONTROL_UPDATE -> removed completely. Log flow control frames instead (e.g., in packet_received or frames_processed)
- PACKET_ACKNOWLEDGED -> removed completely. Log ack frames instead
- PACKET_RETRANSMIT -> instead use recovery.marked_for_retransmit

## Event field name changes and additions

- StreamFrame: .id is now .stream_id
- StreamFrame now has .raw as extra member
- ResetStreamFrame: .id is now .stream_id
- ConnectionCloseFrame: now has .raw_error_code as extra member
- MaxStreamDataFrame: .id is now .stream_id
- TransportError + ApplicationError : entries have been updated to draft-23 specs

