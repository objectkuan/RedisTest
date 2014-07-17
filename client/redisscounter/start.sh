#!/bin/bash

pushd `dirname "$0"` > /dev/null 2>&1
TEST_DIR=`pwd`
popd > /dev/null 2>&1

# Configurations
INSNUM=8
PORT_OFFSET=10000
PARAL=50
TIMES=1
PORT=()
while getopts p:n:c:t:h option
do
	case "$option" in
	p)
		PORT_OFFSET=$OPTARG;;
	n)
		INSNUM=$OPTARG;;
	c)
		PARAL=$OPTARG;;
	t)
		TIMES=$OPTARG;;
	h|\?)
		echo "Usage: $0 [-p from_port] [-n instance_num] [-c para_con] [-t times]"
		exit 0;;
	esac
done

# Enter work dir
cd $TEST_DIR > /dev/null 2>&1

# Configure the ports to use
for (( i=0; i<$INSNUM; i++ )); do
	PORT[$i]=$(($PORT_OFFSET+$i))
done

# Kill all the benchmarks
./killall.sh

# Remove old results
rm ./results/* -f

# Run benchmarks
for (( i=0; i<$INSNUM; i++ )); do
	port=${PORT[$i]}
	for (( j=0; j<$TIMES; j++ )); do
		now=`date "+%Y-%m-%d %T"`
		echo "$now" > results/result-$port-$j
		echo "Redis instance amount: $INSNUM" >> results/result-$port-$j
		echo "Parallel client amount: $PARAL" >> results/result-$port-$j
		echo "" >> results/result-$port-$j
		echo "" >> results/result-$port-$j
		./redis-benchmark -h 10.216.26.44 -p $port -n 100000 -c $PARAL -r 10000000000 >> results/result-$port-$j 2>&1 &
		pids[${#pids[@]}]=$!
		echo "./redis-benchmark -h 10.216.26.44 -p $port -n 100000 -c $PARAL -r 10000000000 >> results/result-$port-$j"
	done;
done;
for pid in ${pids[@]}; do
	wait $pid
done;
echo "Done..."
