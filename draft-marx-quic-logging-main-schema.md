---
title: Main logging schema for qlog
docname: draft-marx-quic-logging-main-schema-latest
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

This document describes a high-level schema for a standardized logging format for
the QUIC and HTTP/3 protocols, called qlog.  This format allows easy sharing of
data and the creation of reusable visualization and debugging tools. 

--- middle

# Introduction

TODO

## Notational Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC2119].

# Overview

TBD

# The High Level Schema

TBD
An early version can be found at https://github.com/quiclog/qlog

# Methods of Access

TBD

# Security Considerations

TBD

# IANA Considerations

TBD

--- back

# Change Log

## Since draft-marx-quic-logging-main-schema-00:

- None yet.

# Design Variations

TBD

# Acknowledgements

Thanks to Jana Iyengar, Dmitri Tikhonov, Jari Arkko, Marcus Ihlar, Victor
Vasiliev and Lucas Pardue for their feedback and suggestions.

