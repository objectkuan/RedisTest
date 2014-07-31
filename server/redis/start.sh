#!/bin/sh

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
		echo "Usage: $0 [-p start_port] [-n instance_amount]"
		exit 0;;
	esac
done

# Enter work dir
cd $TEST_DIR > /dev/null 2>&1

# Configure the ports to use
for (( i=0; i<$INSNUM; i++ )); do
	PORT[$i]=$(($PORT_OFFSET+$i))
done

# Generate configuration files
pushd configs > /dev/null 2>&1
rm config-* -rf
for port in ${PORT[@]}; do
	python genconfig.py --port=$port --appendonly=yes --appendfsync=everysec
	#python genconfig.py --port=$port --appendonly=no --appendfsync=no
	echo "Generate configuration file with Port $port"
done;
popd > /dev/null 2>&1

# Kill all the instances
./killall.sh

# Remove appendonly files
rm ./appendonly/libredis* -f

# Run the instances
for (( i=0; i<$INSNUM; i++ )); do
	port=${PORT[$i]}
	## nothing
	#./redis-server ./configs/config-$port &
	#echo "/redis-server ./configs/config-$port"

	## cgroup
	cgexec -g cpuset:redis_$(($i+1)) ./redis-server configs/config-$port
	echo "cgexec -g cpuset:redis_$(($i+1)) ./redis-server configs/config-$port"

	## early
	#taskset -c $i ./redis-server ./configs/config-$port
	#echo "taskset -c $i ./redis-server ./configs/config-$port"

	## taskset
	#./redis-server ./configs/config-$port &
	#pid=$!
	#taskset -cp $i $pid
	#pids[${#pids[@]}]=$!
	#echo "taskset"
done;
for pid in ${pids[@]}; do
	wait $pid
done;
sleep 10
echo "Started..."
