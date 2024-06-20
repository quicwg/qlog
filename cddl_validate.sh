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
}

# Prepend an object with all the unused types to a CDDL file
# This makes sure there is at least 1 instance of each type to be checked by the cddl tool
# Additionally, this generates sample extensions for type and group sockets defined
# This is especially useful for extension points that are defined, but not yet exercised in the current set of documents
# $1: the input (.cddl) file name
function generate_aux_object() {

    # There are two types of socket extensions: group and type sockets
    # - Group sockets are used to extend existing types with new fields
    # - Type sockets are used to make dynamic lists/ENUMs of types 
    # We want to extract both so we can generate some random extension values for them 
    # to make sure the extension points are usable by future documents

    # the group socket extensions look like this   
    # * $$extension-name
    # nicely on their own row and everything :) so we extract rows that start like that,
    # and then discard the * with regex groups, since we won't need it.
    all_group_sockets=$(awk '/\* (\$\$.+)/ {print $2}' "$1")

    # the type sockets are a bit more involved, usually looking like this
    # $socket-name /= some-value / some-other-value
    # we need to extract just the first part (excluding the /=)
    all_type_sockets=$(awk '/.+ \/=/ {print $1}' "$1")

    # we need to remove the * from before the group sockets
    # in CDDL, the * indicates it's 0 or more
    # this is intentional, as most group sockets aren't used in the current documents, and so 0 is accurate
    # however, to force checking for correct use of the extension, we want the CDDL tool to act as if at least 1 is required
    # we get this by removing the *, so it is forced to look for an actual use of the extension point (which we generate later)
    original_cddl=`cat $1`
    orig="\* \$\$"
    target="\$\$"
    force_group_sockets_cddl="${original_cddl//${orig}/${target}}" # // replaces ALL occurrences
    echo "${force_group_sockets_cddl}" > $1

    # Generate the list of Unused types
    unused_types=$(cddl $1 generate 2>&1 | grep Unused | cut -d " " -f 4)

    # Create an object with all the unused types
    tmpfile=$(mktemp)
    echo "AuxObjectWithAllTypesForValidationOnly = {" >> $tmpfile
    for type in ${unused_types}; do
      lowercase_type=$(echo ${type} | tr '[:upper:]' '[:lower:]')
      # When using CDDL group sockets, they start with $$ 
      # (see https://datatracker.ietf.org/doc/html/rfc8610#section-3.9)
      # These should not be included in the list of all objects here,
      # since this gives validation errors (e.g., $$my-socket-name is not a type)
      # Group sockets aren't types, and shouldn't be listed as such here
      if [[ $lowercase_type != \$\$* ]]; then
        echo "    ${lowercase_type}_: ${type}" >> $tmpfile
      fi
    done
    echo -e "}\n" >> $tmpfile

    # generate sample extension data for the sockets
    for socket in ${all_group_sockets}; do
      # to test if the setup works, replace the next line with an empty echo; 
      # you should see cddl errors :)
      echo "  ${socket} //= ( new_field_name_test_$RANDOM: text )" >> $tmpfile
    done

    for socket in ${all_type_sockets}; do
      # to test if the setup works, search for "new_type_test" in the json output
      # it's a bit random (since the generator can also choose the "real" values if the type socket is being used)
      # but there should be some instances of this in there as well (esp. for ProtocolType in practice)
      echo "  ${socket} /= \"new_type_test_$RANDOM\"" >> $tmpfile
    done

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