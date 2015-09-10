#!/bin/bash

set -euo pipefail

declare -A suffixes
suffixes['sh']=' # <<< configure'

(sed -n -e '/\S/p' | while read name variable; do
    echo "Testing: ${name}"
    inFile="$(ls -1 ./data/${name}.in.* | head -n 1)"
    diffFile="${inFile//.in./.diff.}"

    ./configure \
        --silent \
        --variable-"${variable}" \
        --preprocessor-suffix="${suffixes["${inFile##*.}"]}" \
        --in-file="${inFile}" \
        --out-file="${diffFile}"

    diff "${diffFile}" "${inFile//.in./.out.}"
    rm --force "${diffFile}"

done) <<CASES

    shell VERSION=1.2.3

CASES
