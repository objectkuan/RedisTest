#!/bin/sh

pushd `dirname "$0"` > /dev/null 2>&1
TEST_DIR=`pwd`
popd > /dev/null 2>&1

# Configurations
INSNUM=8
PORT_OFFSET=10000
PORT=()
WAY=0
# 0 for nothing
# 1 for taskset
# 2 for cgroup
ENABLED_FASTSOCKET=0
while getopts p:n:w:f:h option
do
	case "$option" in
	p)
		PORT_OFFSET=$OPTARG;;
	n)
		INSNUM=$OPTARG;;
	w)
		WAY=$OPTARG;;
	f)
		ENABLED_FASTSOCKET=$OPTARG;;
	h|\?)
		echo "Usage: $0 [-p start_port] [-n instance_amount] [-w way] [-f fastsocket]"
		echo "  start_port: the port to start from."
		echo "  instance_amount: the redis instance amount to run."
		echo "  way: way to run redis. 0 for nothing, 1 for taskset, 2 for cgroup"
		echo "  fastsocket: whether to use fastsocket."
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

# Check the way to run
if [ $WAY -eq 0 ]; then
	echo "Run in a normal way"
elif [ $WAY -eq 1 ]; then
	echo "Run in the taskset way"
elif [ $WAY -eq 2 ]; then
	./setupcgroup.sh
	echo "Run in the cgroup way"
fi

# Check fastsocket to probe
if [ $ENABLED_FASTSOCKET -eq 0 ]; then
	echo "Remove fastsocket."
	rmmod fastsocket > /dev/null 2>&1
	FASTSOCKET_OPT=""
else
	echo "Probe fastsocket"
	modprobe fastsocket > /dev/null 2>&1
	FASTSOCKET_OPT="LD_PRELOAD=$TEST_DIR/libfsocket.so "
fi

# Run the instances
for (( i=0; i<$INSNUM; i++ )); do
	port=${PORT[$i]}
	RAW_CMD="$TEST_DIR/redis-server $TEST_DIR/configs/config-$port"
	FIN_CMD="$FASTSOCKET_OPT $RAW_CMD"
	if [ $WAY -eq 0 ]; then
		bash -c "$FIN_CMD &"
		echo "Redis $i started."
	elif [ $WAY -eq 1 ]; then
		taskset -c $i bash -c "$FIN_CMD"
	elif [ $WAY -eq 2 ]; then
		cgexec -g cpuset:redis_$(($i+1)) bash -c "$FIN_CMD"
	fi

	## nothing
	#./redis-server ./configs/config-$port &
	#echo "/redis-server ./configs/config-$port"

	## cgroup
	#cgexec -g cpuset:redis_$(($i+1)) bash -c "LD_PRELOAD=$TEST_DIR/libfsocket.so $TEST_DIR/redis-server configs/config-$port"
	#echo "cgexec -g cpuset:redis_$(($i+1)) ./redis-server configs/config-$port"

	## early
	#taskset -c $i ./redis-server ./configs/config-$port
	#echo "taskset -c $i ./redis-server ./configs/config-$port"

	## taskset
	#./redis-server ./configs/config-$port
	#pid=$!
	#taskset -cp $i $pid
	#pids[${#pids[@]}]=$!
	#echo "taskset"

	## normal fastsocket
	#LD_PRELOAD=$TEST_DIR/libfsocket.so $TEST_DIR/redis-server configs/config-$port
	#echo "normal fastsocket"

	# normal fastsocket
	#cgexec -g cpuset:redis_$(($i+1)) bash -c "LD_PRELOAD=$TEST_DIR/libfsocket.so $TEST_DIR/redis-server configs/config-$port"

	## normal
	#cgexec -g cpuset:redis_$(($i+1)) bash -c "./redis-server ./configs/config-$port"
	#echo "normal"
done;
#for pid in ${pids[@]}; do
#	wait $pid
#done;
sleep 10
echo "Started..."
