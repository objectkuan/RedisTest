#!/bin/sh

CON=(300)
INS=(1 4 8 12)

COUNT=0
FROM=0

while getopts f: option
do
	case "$option" in
	f)
		FROM=$OPTARG;;
	esac
done;

echo "Autotest will skip $FROM cases."


for con in ${CON[@]}; do
	for ins in ${INS[@]}; do
		if [[ $COUNT -lt $FROM ]]; then
			COUNT=$(($COUNT + 1))
			continue
		fi
		echo "[ReTest] ====================================="
		echo "[ReTest] Start $con concur, $ins instances"
		echo "[ReTest] ====================================="
		rm results/$ins-$con* -rf
		./sintest.sh -n $ins -c $con -t 1
		echo "[ReTest] ====================================="
	done;
done;

