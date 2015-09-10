#!/bin/bash

set -euo pipefail

. ./configure

declare -A suffixes
suffixes['sh']=' # <<< configure'

(sed -n -e '/\S/p' | while read name variable; do
    cfg::print_column1 "Testing: ${name}"
    inFile="$(ls -1 ./data/${name}.in.* | head -n 1)"
    diffFile="${inFile//.in./.diff.}"

    ./configure \
        --silent \
        --variable-"${variable}" \
        --preprocessor-suffix="${suffixes["${inFile##*.}"]}" \
        --in-file="${inFile}" \
        --out-file="${diffFile}"

    if diff "${diffFile}" "${inFile//.in./.out.}"; then
        cfg::message_ok
    else
        cfg::message_fail
    fi

    rm --force "${diffFile}"

done) <<CASES

    shell VERSION=1.2.3

CASES
