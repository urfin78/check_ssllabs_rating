#!/bin/bash
declare GRADES=("A+","A-","A","B","C","D","E","F")

usage() { 
    cat <<USAGE
Usage: $0 -h <hostname> [-w <warning>] [-c <critical>]
    -h hostname to check
    -w warning threshold {${GRADES[*]}}
    -c critical threshold {${GRADES[*]}}
USAGE
    exit 1; 
}

send_api_request() {
    if [[ "${2}" == "start" ]]; then
        curl -s "https://api.ssllabs.com/api/v3/analyze?host=${1}&startNew=on" 2>/dev/null
    else 
        curl -s "https://api.ssllabs.com/api/v3/analyze?host=${1}" 2>/dev/null
    fi
}
get_status() {
    echo "${1}"|sed -n -E 's/^.*status\":\"(IN_PROGRESS|DNS|ERROR|READY)\".*$/\1/p'
}
get_grade() {
    echo "${1}"|sed -n -E 's/^.*grade\":\"(A(\+|\-)|[ABCDEFMT])\",.*$/\1/p'
}

while getopts ":h:w:c:" o; do
    case "${o}" in
        h)
            h="${OPTARG}"
            ;;
        c)
            c="${OPTARG}"
            ;;
        w)
            w="${OPTARG}"
            ;;
        \?)
            usage
            ;;
    esac
done
#if [ -z "${c}" ] || [ -z "${w}" ] || [ -z "${h}" ]; then
if [ -z "${h}" ]; then
    usage
fi

DATA=$(send_api_request ${h} start)
PROGRESS=0
while [[ ${PROGRESS} -lt 1 ]]; do
    sleep 10
    DATA="$(send_api_request ${h})"
    STATUS="$(get_status ${DATA})"
    if [[ "${STATUS}" == "READY" ]]; then
        PROGRESS=1
        GRADE="$(get_grade ${DATA})"
    fi
done
echo "${GRADE}"
