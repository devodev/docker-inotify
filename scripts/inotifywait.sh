#!/usr/bin/env bash

INOTIFY_QUIET="${INOTIFY_QUIET:-"true"}"

[ $# -ne 2 ] && { echo "USAGE: ${BASH_SOURCE[0]} <TARGET> <SCRIPT>"; exit 1; }

TARGET="${1}"; shift
SCRIPT="${1}"; shift

# bool accepted values: "true", "false"
INOTIFY_CFG_CSV="${INOTIFY_CFG_CSV:-"false"}"
INOTIFY_CFG_QUIET="${INOTIFY_CFG_QUIET:-"true"}"
INOTIFY_CFG_RECURSIVE="${INOTIFY_CFG_RECURSIVE:-"false"}"
# variables set to "-" are ignored
INOTIFY_CFG_EXCLUDE="${INOTIFY_CFG_EXCLUDE:-"-"}"
INOTIFY_CFG_EXCLUDEI="${INOTIFY_CFG_EXCLUDEI:-"-"}"
INOTIFY_CFG_INCLUDE="${INOTIFY_CFG_INCLUDE:-"-"}"
INOTIFY_CFG_INCLUDEI="${INOTIFY_CFG_INCLUDEI:-"-"}"
INOTIFY_CFG_EVENTS="${INOTIFY_CFG_EVENTS:-"modify delete delete_self"}"
INOTIFY_CFG_TIMEFMT="${INOTIFY_CFG_TIMEFMT:-"%H:%M:%S"}"
INOTIFY_CFG_TIMEOUT="${INOTIFY_CFG_TIMEOUT:-"-"}"

function log { [ "${INOTIFY_QUIET}" != "true" ] && echo "[$(date -Iseconds)] ${*}"; }

function join { printf -- "${1}%s" "${@:2}"; }
function setboolflag { [ "${2}" = "true" ] && echo "${1}"; }
function setflag { [ "${2}" != "-" ] && printf "%s=%s" "${1}" "${2}"; }

function watch {
    IFS=" " read -r -a cfg_events <<< "${INOTIFY_CFG_EVENTS}"
    log "Watching events '${cfg_events[*]}' for '${TARGET}'"

    inotifywait --monitor \
        --no-newline \
        --format "%T%0%w%0%e%0%f%0" \
        "$(setboolflag --csv        "${INOTIFY_CFG_CSV}")"        \
        "$(setboolflag --quiet      "${INOTIFY_CFG_QUIET}")"      \
        "$(setboolflag --recursive  "${INOTIFY_CFG_RECURSIVE}")"  \
        "$(setflag     --exclude    "${INOTIFY_CFG_EXCLUDE}")"    \
        "$(setflag     --excludei   "${INOTIFY_CFG_EXCLUDEI}")"   \
        "$(setflag     --include    "${INOTIFY_CFG_INCLUDE}")"    \
        "$(setflag     --includei   "${INOTIFY_CFG_INCLUDEI}")"   \
        "$(setflag     --timefmt    "${INOTIFY_CFG_TIMEFMT}")"    \
        "$(setflag     --timeout    "${INOTIFY_CFG_TIMEOUT}")"    \
        "${cfg_events[@]/#/-e}" \
        "$(realpath "${TARGET}")" | while
            IFS= read -r -d '' time && \
            IFS= read -r -d '' watched && \
            IFS= read -r -d '' events && \
            IFS= read -r -d '' file; do
            log "New event (${events}) detected for '${watched}' (time:${time} file:'${file}')"
            "$(realpath "${SCRIPT}")" "${time}" "${watched}" "${events}" "${file}"
        done
}

while true; do
    if [ ! -e "${TARGET}" ]; then
        log "Waiting for '${TARGET}' to appear..."
        sleep 1
        continue
    fi

    watch
done
