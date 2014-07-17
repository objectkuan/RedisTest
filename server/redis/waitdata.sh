#!/bin/bash
COUNTER=0
while true; do
	res=`sar -P ALL -u ALL 1 2 | grep all | grep Average`
	cpu=${res:100}
	if [ `echo "$cpu > 98"| bc` -eq 1 ] ; then
		echo ""
		echo "OK"
		break
	else
		COUNTER=$(($COUNTER + 2))
		echo -ne "Wait - $COUNTER\r"
	fi
done
