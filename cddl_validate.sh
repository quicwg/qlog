#!/usr/bin/env bash
#
# requires `gem install cddl`
#
set -e
set -o nounset

INPUT_FILE="$1"
BASE_FILENAME="${INPUT_FILE%.*}"
CDDL_FILE="${BASE_FILENAME}.cddl"
CDDL_JSON_FILE="${BASE_FILENAME}.json"

:> $CDDL_FILE

# Extracts CDDL from a markdown file
# $1: the input (.md) file
# $2: the output (.cddl) file
function extract_cddl() {
    cat $1 | awk 'BEGIN{flag=0} /~~~ cddl/{flag=1; printf "\n"; next} /~~~/{flag=0; next} flag' >> $2
    #sed -n '/^```cddl/,/^```/p' $1 | sed '1d;$d' >> $2
}

# Prepend an object with all the unused types to a CDDL file
# $1: the input (.cddl) file
function generate_aux_object() {
    # Generate the list of Unused types
    unused_types=$(cddl $1 generate 2>&1 | grep Unused | cut -d " " -f 4)
    # Create an object with all the unused types
    tmpfile=$(mktemp)
    echo "AuxObjectWithAllTypesForValidationOnly = {" >> $tmpfile
    for type in ${unused_types}; do
      lowercase_type=$(echo ${type} | tr '[:upper:]' '[:lower:]')
      echo "    ${lowercase_type}_: ${type}" >> $tmpfile
    done
    echo -e "}\n" >> $tmpfile

    tmpfile2=$(mktemp)
    cat $tmpfile $1 > $tmpfile2
    mv $tmpfile2 $1
}

if [ $INPUT_FILE != "draft-ietf-quic-qlog-main-schema.md" ]; then
    # Extracts CDDL from the main schema file
    extract_cddl draft-ietf-quic-qlog-main-schema.md $CDDL_FILE
fi

extract_cddl $INPUT_FILE $CDDL_FILE
generate_aux_object $CDDL_FILE

# The cddl command doesn't know how to work with .regexp with a give size.
# We use that with hexstring sometimes, so clean that up
tmpfile=$(mktemp)
sed "s/hexstring .size .*/hexstring/" $CDDL_FILE > $tmpfile
mv $tmpfile $CDDL_FILE

# run the CDDL validator and generate the sample JSON file
cddl ${CDDL_FILE} json-generate > ${CDDL_JSON_FILE}
