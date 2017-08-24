#!/bin/bash

set -x

PINGNUM=10

usage() {
    echo "$(basename "${0}") [-c <ping number>] [-h]"
    echo ''
}

while getopts c:h OPT
do
    case "$OPT" in
	h)
	    usage
	    exit 0
	    ;;
	c)
	    PINGNUM=${OPTARG}
	    ;;
	*)
	    exit 1
	    ;;
    esac
done

set -o pipefail

GATEWAYIP=$(route -n | awk '$4 == "UG" {print $2}' | head -n1)

if [ -z "${GATEWAYIP}" ]; then
    echo "Failed to retrieve gateway ip"
    lava-test-case gateway-ip --result fail
    lava-test-case ping --result skip
    exit 0
else
    lava-test-case gateway-ip --result pass
fi

OUT=$(ping -c ${PINGNUM} ${GATEWAYIP})
if [ "${?}" != "0" ]; then
    echo "ping command failed"
    lava-test-case ping --result fail
    exit 0
fi

LOSS=$(echo ${OUT} | grep -oE '[0-9]+% packet loss' | cut -f1 -d'%')
AVG=$(echo ${OUT} | grep -oE '/[0-9.]+/' | cut -f2 -d'/')
if [ "${LOSS}" != "0" ]; then
    RET="fail"
else
    RET="pass"
fi

lava-test-case ping --result ${RET} --measurement ${LOSS} --units percent
lava-test-case ping --result ${RET} --measurement ${AVG} --units milliseconds
exit 0