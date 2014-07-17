#!/bin/bash

INSNUM=1
PORT_OFFSET=10000

while getopts n: option
do
	case "$option" in
	p)
		PORT_OFFSET=$OPTARG;;
	n)
		INSNUM=$OPTARG;;
	esac
done;

COUNT=0
for (( i=0; i<$INSNUM; i++ )); do
	port=$(($PORT_OFFSET+$i))
	while true; do
		result=`nc -n -z -w 1 10.216.26.44 $port | grep "succeeded"`
		if [ ! -z "$result" ]; then
			echo ""
			echo "Port is OK"
			break;
		else
			COUNT=$(($COUNT + 1))
			echo -ne "Port is not OK - $COUNT\r"
		fi
	done
done


