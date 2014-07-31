#!/bin/bash

pushd `dirname "$0"` > /dev/null 2>&1
TEST_DIR=`pwd`
popd > /dev/null 2>&1

# Configurations
INSNUM=8
PORT_OFFSET=10000
PORT=()
while getopts p:n:h option
do
	case "$option" in
	p)
		PORT_OFFSET=$OPTARG;;
	n)
		INSNUM=$OPTARG;;
	h|\?)
		echo "Usage: $0 [-p from_port] [-n instance_num]"
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
mkdir -p ./results
rm ./results/* -f

# Run benchmarks
for (( i=0; i<$INSNUM; i++ )); do
	port=${PORT[$i]}
	./redis-benchmark -h 192.168.0.180 -p $port -t set -n 100000000 -r 10000000000 &
	pids[${#pids[@]}]=$!
	echo "./redis-benchmark -h 192.168.0.180 -p $port -t set -n 100000000 -r 10000000000 &"
done;

for pid in ${pids[@]}; do
	wait $pid
done;

echo "Done..."
