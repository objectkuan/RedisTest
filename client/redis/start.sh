#!/bin/bash

pushd `dirname "$0"` > /dev/null 2>&1
TEST_DIR=`pwd`
popd > /dev/null 2>&1

# Configurations
INSNUM=8
PORT_OFFSET=10000
PARAL=50
PORT=()
SERVER="127.0.0.1"
while getopts p:n:c:s:h option
do
	case "$option" in
	p)
		PORT_OFFSET=$OPTARG;;
	n)
		INSNUM=$OPTARG;;
	c)
		PARAL=$OPTARG;;
	s)
		SERVER=$OPTARG;;
	h|\?)
		echo "Usage: $0 [-p from_port] [-n instance_num] [-c para_con] [-s server_ip]"
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
echo "remove things"
mkdir -p ./results
rm ./results/* -f

# Run benchmarks
for (( i=0; i<$INSNUM; i++ )); do
	port=${PORT[$i]}
	TIMES=$(( $PARAL / 25 ))
	for (( j=0; j<$TIMES; j++ )); do
		now=`date "+%Y-%m-%d %T"`
		echo "$now" > results/result-$port-$j
		echo "Redis instance amount: $INSNUM" >> results/result-$port-$j
		echo "Parallel client amount: $PARAL" >> results/result-$port-$j
		echo "" >> results/result-$port-$j
		echo "" >> results/result-$port-$j
		./redis-benchmark -h $SERVER -p $port -l -n 100000 -t get -c 25 -r 10000000000 >> results/result-$port-$j 2>&1 &
		pids[${#pids[@]}]=$!
		echo "./redis-benchmark -h $SERVER -p $port -l -n 100000 -t get -c 25 -r 10000000000 >> results/result-$port-$j"
	done;
done;

for pid in ${pids[@]}; do
	wait $pid
done;


echo "Done..."
