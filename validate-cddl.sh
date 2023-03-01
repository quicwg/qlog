#!/bin/bash
set -e
set -o nounset

CDDL_FILENAME="http.cddl"
:> $CDDL_FILENAME

cat << EOF >> $CDDL_FILENAME
uint8 = uint .size 1
uint16 = uint .size 2
uint32 = uint .size 4
uint64 = uint .size 8
hexstring = text
UnknownFrame = {
    frame_type: text .default "unknown"
    raw_frame_type: uint64
    ? raw_length: uint
    ? raw: RawInfo
}
RawInfo = {
    ? length: uint64
    ? payload_length: uint64
    data: hexstring
}
EOF

# Generate the list of Unused types
cat draft-ietf-quic-qlog-h3-events.md | awk 'BEGIN{flag=0} /~~~ cddl/{flag=1; printf "\n"; next} /~~~/{flag=0; next} flag' >> $CDDL_FILENAME
unused_types=$(cddl $CDDL_FILENAME generate 2>&1 | grep Unused | cut -d " " -f 4)

tmpfile=$(mktemp)
echo "HTTPValidationAggregator = {" >> $tmpfile
for type in ${unused_types}; do
  lowercase_type=$(echo ${type} | tr '[:upper:]' '[:lower:]')
  echo "    ${lowercase_type}_: ${type}" >> $tmpfile
  # print the type anchors
  #echo -n "{"
  #echo ": #${lowercase_type}-def title=\"${type} definition\"}"
done
echo -e "}\n" >> $tmpfile

tmpfile2=$(mktemp)
cat $tmpfile $CDDL_FILENAME > $tmpfile2
mv $tmpfile2 $CDDL_FILENAME

cddl ${CDDL_FILENAME} generate