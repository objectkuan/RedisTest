#!/bin/bash
IFACE="eth5"
queue=0

cpus=(0 1 2 3 4 5 6 7 8 9 10 11)
#cpus=(1 3 5 7 9 11 0 2 4 6 8 10)
#cpus=(0 2 4 6 8 10 1 3 5 7 9 11)

while getopts i:h option
do
	case "$option" in
	i)
		IFACE=$OPTARG;;
	h|\?)
		echo "Usage: $0 [-i nic]"
		exit 0;;
	esac
done

while [ $queue -lt 12 ]; do
	port=$((10000 + $queue))
	ethtool -U $IFACE flow-type tcp4 dst-port $port action ${cpus[$queue]}
	queue=$(($queue + 1))
done;
