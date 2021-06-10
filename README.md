# qlog drafts

This is the working area for IETF [QUIC Working Group](https://datatracker.ietf.org/wg/quic/documents/) Internet-Drafts concerning the qlog logging format for QUIC and HTTP/3.

Three documents are currently defined:
- The main schema: high-level schema, defining general logging format and principles
- Event definitions for QUIC: concrete event definitions for the QUIC protocol
- Event definitions for HTTP/3 and QPACK: concrete event definitions for the HTTP/3 and QPACK protocols

## Main logging schema for qlog

* [Editor's Copy](https://quicwg.github.io/qlog/#go.draft-ietf-quic-qlog-main-schema.html)
* [Working Group Draft](https://datatracker.ietf.org/doc/html/draft-ietf-quic-qlog-main-schema)
* [Compare Editor's Copy to Working Group Draft](https://quicwg.github.io/qlog/#go.draft-ietf-quic-qlog-main-schema.diff)

## QUIC event definitions for qlog

* [Editor's Copy](https://quicwg.github.io/qlog/#go.draft-ietf-quic-qlog-quic-events.html)
* [Working Group Draft](https://datatracker.ietf.org/doc/html/draft-ietf-quic-qlog-quic-events)
* [Compare Editor's Copy to Working Group Draft](https://quicwg.github.io/qlog/#go.draft-ietf-quic-qlog-quic-events.diff)

## HTTP/3 and QPACK event definitions for qlog

* [Editor's Copy](https://quicwg.github.io/qlog/#go.draft-ietf-quic-qlog-h3-events.html)
* [Working Group Draft](https://datatracker.ietf.org/doc/html/draft-ietf-quic-qlog-h3-events)
* [Compare Editor's Copy to Working Group Draft](https://quicwg.github.io/qlog/#go.draft-ietf-quic-qlog-h3-events.diff)


## Building the Draft

Formatted text and HTML versions of the draft can be built using `make`.

```sh
$ make
```

This requires that you have the necessary software installed.  See
[the instructions](https://github.com/martinthomson/i-d-template/blob/main/doc/SETUP.md).


## Contributing

See the
[guidelines for contributions](https://github.com/quicwg/qlog/blob/main/CONTRIBUTING.md).
