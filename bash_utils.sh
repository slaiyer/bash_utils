#!/usr/bin/env bash

# Bash helper library

################################################################################

# Define default shell behaviour
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

# ANSI codes and common combinations
export n=$'\e[0m'
export b=$'\e[1m'
export d=$'\e[2m'
export i=$'\e[3m'
export u=$'\e[4m'
export k=$'\e[5m'
export v=$'\e[7m'
export h=$'\e[8m'
export sqo="${d}[${n}"
export sqc="${d}]${n}"
export red=$'\e[31m'
export grn=$'\e[32m'
export yel=$'\e[33m'
export blu=$'\e[34m'

# Print stack trace
trace() {
    local error="${?}"
    set +o xtrace
    log_msg 'ERROR' "\`${BASH_COMMAND}\` exited with status ${error}"

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

        printf '%s' "${text}" \
            | column -ts '|' \
            | sed -u 's/^/\t/' 1>&2
    fi

    exit "${1:-1}"
}

export -f trace

# Set trap on error
trap 'trace "${?}' ERR

# Check if specified binary is available in PATH
require() { # Parameters: bin_list
    local -a bin_list=( "${@}" )
    for binary in "${bin_list[@]}"; do
        command -v "${binary}" > /dev/null 2>&1 \
            || {
                log_msg 'ABORT' "Could not locate '${binary}' executable"
                exit 1
            }
    done
}

export -f require

# Print timestamped message to the selected stream
log_msg() { # Parameters: class, text, force
    local verb_lvl="${verbosity:-1}"
    local class="${1:-WARN}"
    local text="${2:-Lorem ipsum dolor sit amet}"
    local stream=1
    local color=''

    # Print current message irrespective of global verbosity level
    [[ "${3:-default}" == 'force' ]] \
        && verb_lvl=2

    case "${class}" in
        INFO)
            (( verb_lvl < 2 )) \
                && return
            color="${blu}"
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

    printf '\n%s %s %s\n' \
        "${d}$(timestamp)${n}" \
        "${sqo}${color}${class}${n}${sqc}" \
        "${text}" \
        1>&"${stream}"
}

export -f log_msg

# Return current timestamp
timestamp() {
    date '+%F %T %z' \
        || log_msg 'WARN' 'Could not acquire timestamp'
}

export -f timestamp
