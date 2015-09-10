#!/bin/bash

set -euo pipefail

############################################################
#
#               Developer configuration
#
############################################################

# Lines with this suffix will be preprocessed
preprocessorSuffix='# <<< configure'

# Usually Makefile
inFile='Makefile'

# Usually Makefile
outFile="${inFile}"

# Configuration variables.
# Theese will be read from commandline arguments set by the en-user
declare -A variables
# variables['INSTALL_PATH']="${HOME}/bin"
# variables['VERSION']='0.2.0'

# Your Name <your.email@example.com>
author='Roman Piták <roman@pitak.net>'

#
helpMessage='
This is a ./configure script.

SYNOPSIS:
\t./configure --option=value --option=value ...

OPTIONS:
\t--install-path           : Where will I be installed?
\t--invocation-command     : How will you be calling me?
'
#
successMessage='
Configuration successfull!
You can now run
\n\tmake && make install\n
to complete the installation.
'
############################################################
#              End of developer configuration
############################################################
# There should be no need to edit below this line.

pr_help() {
    echo -e "${helpMessage}"
    echo -e '\nDEFAULT VALUES:'
    for key in "${!variables[@]}"; do
        option="--$(echo ${key,,} | sed -e 's/_/-/')"
        echo -e "\t${option}=${variables[$key]}"
    done
    echo -e "\nAUTHOR:\n\t${author}"
}

pr_preprocessor() {
    sedFile="$(mktemp)"
    for key in "${!variables[@]}"; do
        echo "${key}=${variables["${key}"]}"
        echo "${key} = ${variables["${key}"]}"
    done | gawk '
        BEGIN {FS="="; preprocessorSuffix="'"${preprocessorSuffix}"'"}
        {
            gsub(/\//,"\\/", $2)
            gsub(/\//,"\\/", preprocessorSuffix)
            print "s/^" $1 "=.*" preprocessorSuffix "$/" $1 "=" $2 preprocessorSuffix "/"
        }
    '  > "${sedFile}"
    sed --file="${sedFile}"
    rm "${sedFile}"
}

declare -A overrideVariables
overrideVariables=()
stdOut='/dev/stdout'
stdErr='/dev/stderr'
while [[ $# > 0 ]]; do
    case "${1}" in
        -h|--help)
            pr_help; exit 0
            ;;
        --in-file=*)
            inFileArg="${1//--in-file=/}"
            ;;
        --out-file=*)
            outFileArg="${1//--out-file=/}"
            ;;
        --preprocessor-suffix=*)
            preprocessorSuffix="${1//--preprocessor-suffix=/}"
            ;;
        --silent)
            stdOut='/dev/null'
            ;;
        --variable-*)  # non-default variables
            assignment="${1//--variable-/}"
            overrideVariables["${assignment//=*/}"]="${assignment//*=/}"
            ;;
        *)  # defaultVariables processing
            # convert --install-path to INSTALL_PATH
            key="$(echo "${1^^}" | sed -e 's/^--//' -e 's/-/_/' -e 's/=.*$//')"
            if test "${variables[$key]+isset}"; then
                variables["${key}"]="$(echo "${1}" | sed -e 's/^[^=]*=//')"
            else
                echo "Unknown option \"${1}\"" >> "${stdErr}"; pr_help; exit 63
            fi
            ;;
    esac
    shift
done

if test -n "${inFileArg+isset}" && test -n "${outFileArg+isset}"; then

    if test '-' == "${inFileArg}"; then
        inFile='/dev/stdin'
    else
        inFile="${inFileArg}"
    fi

    if test '-' == "${outFileArg}"; then
        outFile='/dev/stdout'
    else
        outFile="${outFileArg}"
    fi

elif test -n "${inFileArg+isset}" || test -n "${outFileArg+isset}"; then
    echo '--in-file and --out-file must always be together' >> "${stdErr}"
    exit 1
fi

if test 0 -ne ${#overrideVariables[@]}; then
    unset variables
    declare -A variables
    for key in ${!overrideVariables[@]}; do
        variables["${key}"]="${overrideVariables["${key}"]}"
    done
fi

tmpOutFile="$(mktemp)"
pr_preprocessor < "${inFile}" > ${tmpOutFile}
cat "${tmpOutFile}" > "${outFile}"
rm --force "${tmpOutFile}"
echo -e "${successMessage}" >> "${stdOut}"
