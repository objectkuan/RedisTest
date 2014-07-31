#!/bin/bash
COUNTER=0
while true; do
	res=`sar -P ALL -u ALL 1 2 | grep all | grep Average`
	cpu=${res:100}
	res=`echo "$cpu > 99"| bc`
	if [ $res -gt 0 ] ; then
		echo ""
		echo "OK"
		break
	else
		COUNTER=$(($COUNTER + 2))
		echo -ne "Wait - $COUNTER\r"
	fi
done
