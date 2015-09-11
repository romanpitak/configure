#!/bin/bash

set -euo pipefail

###############################################################################
#
#                           Developer configuration
#
###############################################################################

# Lines with this suffix will be preprocessed
cfg__suffix='# <<< configure'

# Usually Makefile
cfg__in_file='Makefile'

# Usually Makefile
cfg__out_file="${cfg__in_file}"

# Configuration variables.
# Theese will be read from commandline arguments set by the end-user
# All keys MUST be uppercase
declare -A cfg__variables
# cfg__variables['INSTALL_PATH']="${HOME}/bin"
# cfg__variables['VERSION']='0.2.0'

# Your Name <your.email@example.com>
cfg__author='Roman Piták <roman@pitak.net>'

#
cfg__help_message='
This is a ./configure script.

SYNOPSIS:
\t./configure --option=value --option=value ...

OPTIONS:
\t--install-path           : Where will I be installed?
\t--invocation-command     : How will you be calling me?
'
#
cfg__success_message='
Configuration successfull!
You can now run
\n\tmake && make install\n
to complete the installation.
'

#
cfg__align_width=${cfg__align_width:-70}
###############################################################################
#                      End of developer configuration
###############################################################################
# There should be no need to edit below this line.

###############################################################################
# Align cursor
#
# Globals:
#   cfg__align_width
# Arguments:
#   None
# Returns:
#   None
###############################################################################
if command -v tput >/dev/null 2>&1 && test -t 1; then
    function cfg::align() {
        tput hpa "${cfg__align_width}"
    }
else
    function cfg::align() {
        printf "\n%${cfg__align_width}s" ' '
    }
fi

function cfg::print_column1() {
    printf '%s' "$1"
}
function cfg::print_column2() {
    cfg::align
    printf '%s\n' "$1"
}

###############################################################################
# Color output
#
# Globals:
#   None
# Arguments:
#   message_text
# Returns:
#   None
###############################################################################
if command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1 && test -t 1; then
    function cfg::color_print() {
        tput setaf $1
        printf '%s' "$2"
        tput setaf 9
    }
    function cfg::color_red()      { cfg::color_print 1 "$1"; }
    function cfg::color_green()    { cfg::color_print 2 "$1"; }
    function cfg::color_yellow()   { cfg::color_print 3 "$1"; }
    function cfg::color_blue()     { cfg::color_print 4 "$1"; }
    function cfg::color_magenta()  { cfg::color_print 5 "$1"; }
    function cfg::color_cyan()     { cfg::color_print 6 "$1"; }
else # fallback
    function cfg::color_red()      { printf '%s' "$1"; }
    function cfg::color_green()    { printf '%s' "$1"; }
    function cfg::color_yellow()   { printf '%s' "$1"; }
    function cfg::color_blue()     { printf '%s' "$1"; }
    function cfg::color_magenta()  { printf '%s' "$1"; }
    function cfg::color_cyan()     { printf '%s' "$1"; }
fi

function cfg::message_failed() {
    cfg::print_column2 "$(cfg::color_red '[FAILED]')"
}

function cfg::message_ok() {
    cfg::print_column2 "$(cfg::color_green '[OK]')"
}

###############################################################################
# Print error message
#
# Globals:
#   cfg__std_err
# Arguments:
#   message_text
# Returns:
#   None
###############################################################################
function cfg::error() {
    printf '\n%s\n' "$(cfg::color_red "${1}")" >> "${cfg__std_err}"
}

###############################################################################
# Fatal error. Print error message and exit.
#
# Globals:
#   None
# Calls:
#   cfg::error
# Arguments:
#   message_text
#   exit_code
# Returns:
#   None
###############################################################################
function cfg::fatal() {
    cfg::error "${1}"
    exit "${2:-1}"
}

###############################################################################
# Print help
#
# Globals:
#   cfg__author
#   cfg__help_message
#   cfg__variables
# Arguments:
#   None
# Returns:
#   None
###############################################################################
function cfg::help() {
    local key
    local option
    printf "${cfg__help_message}\n\nDEFAULT VALUES:\n"
    for key in "${!cfg__variables[@]}"; do
        option="--$(echo ${key,,} | sed -e 's/_/-/')"
        printf "\t${option}=${cfg__variables[$key]}\n"
    done
    printf "\nAUTHOR:\n\t${cfg__author}\n"
}

###############################################################################
# Replace preprocessor directives with proper values
#
# Reads from stdin and writes into stdout.
#
# Globals:
#   cfg__suffix
#   cfg__variables
# Arguments:
#   None
# Returns:
#   None
###############################################################################
function cfg::preprocessor() {
    local key
    local sed_script_file
    sed_script_file="$(mktemp)"
    for key in "${!cfg__variables[@]}"; do
        printf "${key}=${cfg__variables["${key}"]}\n"
        printf "${key} = ${cfg__variables["${key}"]}\n"
    done | gawk \
        --assign FS="=" \
        --assign ppsuffix="${cfg__suffix}" '
        {
            gsub(/\//,"\\/", $2)
            gsub(/\//,"\\/", ppsuffix)
            print "s/^" $1 "=.*" ppsuffix "$/" $1 "=" $2 ppsuffix "/"
        }
        ' > "${sed_script_file}"
    sed --file="${sed_script_file}"
    rm --force "${sed_script_file}"
}

###############################################################################
# Prepair preprocessor environment and run preprocessor
#
# Globals:
#   cfg__in_file_arg
#   cfg__in_file
#   cfg__out_file_arg
#   cfg__out_file
#   cfg__override_variables
#   cfg__success_message
#   cfg__std_out
#   cfg__variables
# Arguments:
#   None
# Returns:
#   None
###############################################################################
function cfg::run_preprocessor() {
    if test -n "${cfg__in_file_arg:-}" && test -n "${cfg__out_file_arg:-}"; then

        if test '-' == "${cfg__in_file_arg}"; then
            cfg__in_file='/dev/stdin'
        else
            cfg__in_file="${cfg__in_file_arg}"
        fi

        if test '-' == "${cfg__out_file_arg}"; then
            cfg__out_file='/dev/stdout'
        else
            cfg__out_file="${cfg__out_file_arg}"
        fi

    elif test -n "${cfg__in_file_arg:-}" || test -n "${cfg__out_file_arg:-}"; then
        cfg::fatal '--in-file and --out-file must always be together'
    fi

    if test 0 -ne ${#cfg__override_variables[@]}; then
        local key
        unset cfg__variables
        declare -A cfg__variables
        for key in ${!cfg__override_variables[@]}; do
            cfg__variables["${key}"]="${cfg__override_variables["${key}"]}"
        done
    fi

    local tmp_out_file="$(mktemp)"
    cfg::preprocessor < "${cfg__in_file}" > ${tmp_out_file}
    cat "${tmp_out_file}" > "${cfg__out_file}"
    rm --force "${tmp_out_file}"
    printf "${cfg__success_message}" >> "${cfg__std_out}"
}

###############################################################################
# Unset global variables and functions you don't want to be sourced.
#
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
###############################################################################
function cfg::unset_globals() {
    unset cfg__author
    unset cfg__assignment
    unset cfg__help_message
    unset cfg__in_file
    unset cfg__is_sourced
    unset cfg__key
    unset cfg__out_file
    unset cfg__override_variables
    unset cfg__std_err
    unset cfg__std_out
    unset cfg__success_message
    unset cfg__suffix

    unset -f cfg::help
    unset -f cfg::preprocessor
    unset -f cfg::run_preprocessor
}

###############################################################################
#                     command line arguments processing
###############################################################################

# Before shifting the arguments, check if the script is being sourced.
if test "$0" != "$BASH_SOURCE"; then
    cfg__is_sourced='True'
fi

# process commandline arguments
declare -A cfg__override_variables
cfg__override_variables=()
cfg__std_out='/dev/stdout'
cfg__std_err='/dev/stderr'
while [[ $# > 0 ]]; do
    case "${1}" in
        -h|--help)
            cfg::help; exit 0
            ;;
        --in-file=*)
            cfg__in_file_arg="${1//--in-file=/}"
            ;;
        --out-file=*)
            cfg__out_file_arg="${1//--out-file=/}"
            ;;
        --preprocessor-suffix=*)
            cfg__suffix="${1//--preprocessor-suffix=/}"
            ;;
        --silent)
            cfg__std_out='/dev/null'
            ;;
        --variable-*)  # non-default variables
            cfg__assignment="${1//--variable-/}"
            cfg__override_variables["${cfg__assignment//=*/}"]="${cfg__assignment//*=/}"
            ;;
        *)  # defaultVariables processing
            # convert --install-path to INSTALL_PATH
            cfg__key="$(echo "${1^^}" | sed -e 's/^--//' -e 's/-/_/' -e 's/=.*$//')"
            if test "${cfg__variables[$cfg__key]+isset}"; then
                cfg__variables["${cfg__key}"]="$(echo "${1}" | sed -e 's/^[^=]*=//')"
            else
                cfg::help
                cfg::fatal "\nUnknown option \"${1}\"" 63
            fi
            ;;
    esac
    shift
done

###############################################################################
#                                  main
###############################################################################

if test -n "${cfg__is_sourced:-}"; then
    cfg::unset_globals
else
    cfg::run_preprocessor
fi
