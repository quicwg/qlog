---
title: Concrete QUIC and HTTP/3 event definitions for qlog
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
QUIC and HTTP/3-related events. These events SHOULD be embedded in the higher
level schema defined in draft-marx-quic-logging-main-schema-latest.

--- middle

# Introduction

TODO

## Notational Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC2119].

# Overview

TBD

# QUIC event definitions

TBD

# HTTP/3 event definitions

TBD

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

Thanks to Jana Iyengar, Dmitri Tikhonov, Jari Arkko, Marcus Ihlar, Victor
Vasiliev and Lucas Pardue for their feedback and suggestions.

