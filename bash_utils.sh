#!/usr/bin/env bash

# Bash helper library
# Tested with Bash 4.4

################################################################################

# Define default shell behaviour
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

################################################################################

# ANSI codes and common combinations
declare -rx n=$'\e[0m'
declare -rx b=$'\e[1m'
declare -rx d=$'\e[2m'
declare -rx i=$'\e[3m'
declare -rx u=$'\e[4m'
declare -rx k=$'\e[5m'
declare -rx v=$'\e[7m'
declare -rx h=$'\e[8m'
declare -rx sqo="${d}[${n}"
declare -rx sqc="${d}]${n}"
declare -rx red=$'\e[31m'
declare -rx grn=$'\e[32m'
declare -rx yel=$'\e[33m'
declare -rx blu=$'\e[34m'

# Print stack trace
trace() { # Parameters: last_exit_code
    local -ir code="${?}"
    set +o xtrace
    log 'ERROR' "\`${BASH_COMMAND}\` exited with status ${code}"

    if (( "${#FUNCNAME[@]}" > 2 )); then
        printf '%s:\n' "${b}Stack trace${n}" 1>&2

        local text=''
        for (( idx = 0; idx < "${#FUNCNAME[@]}" - 1; ++idx )); do
            text="${text}${d}${idx}.${n}"
            text="${text}|${i}${BASH_SOURCE["${idx}" + 1]}${n}"
            text="${text}|${d}:${n}${v}${BASH_LINENO["${idx}"]}${n}"
            text="${text}|${b}${FUNCNAME["${idx}"]}${n}"
            text="${text}"$'\n'
        done
        unset -v idx
        local -r text

        printf '%s' "${text}" \
            | column -t -s '|' \
            | sed -u 's/^/\t/' 1>&2
    fi

    exit "${1:-1}"
}

# shellcheck disable=SC2154
declare -fx trace

# Set trap on error
trap 'trace "${?}"' ERR

# Check if specified command is available in PATH
require() { # Parameters: cmd_list
    local -ar cmd_list=( "${@}" )
    for cmd in "${cmd_list[@]}"; do
        command -vq "${@}" \
            || {
                log 'ABORT' "Could not detect '${cmd}'"
                exit 1
            }
    done
    unset -v cmd
}

# shellcheck disable=SC2154
declare -fx require

# Reset formatting
reset_fmt() {
    printf '%s' "${n}"
}

# shellcheck disable=SC2154
declare -fx require

# Print timestamped message to the selected stream
log() { # Parameters: class, text, force_print
    local -i verb_lvl="${verbosity:-1}"
    local -r class="${1:-WARN}"
    local -r text="${2:-Lorem ipsum dolor sit amet}"
    local -r force_print="${3:-default}"
    local -i stream=1
    local color=''

    # Print current message irrespective of global verbosity level
    [[ "${force_print}" == 'force' ]] \
        && verb_lvl=2
    local -r verb_lvl

    case "${class}" in
        DEBUG)
            (( verb_lvl < 3 )) \
                && return
            color="${blu}"
            ;;
        INFO)
            (( verb_lvl < 2 )) \
                && return
            color="${grn}"
            ;;
        WARN)
            (( verb_lvl < 1 )) \
                && return
            stream=2
            color="${b}${yel}"
            ;;
        ABORT)
            stream=2
            color="${red}"
            ;;
        ERROR)
            stream=2
            color="${b}${red}"
            ;;
        FATAL)
            stream=2
            color="${b}${red}${v}${k}"
            ;;
    esac
    local -r stream

    reset_fmt 1>&${stream}
    printf '\n%s %s %s\n' \
        "${d}$(timestamp)${n}" \
        "${sqo}${color}${class}${n}${sqc}" \
        "${text}" \
        1>&${stream}
    reset_fmt 1>&${stream}
}

# shellcheck disable=SC2154
declare -fx log

# Return current timestamp
timestamp() {
    date -I'seconds' \
        || log 'WARN' 'Could not acquire timestamp'
}

# shellcheck disable=SC2154
declare -fx timestamp

require 'column' 'sed' 'date'
