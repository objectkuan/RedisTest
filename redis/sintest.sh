#!/bin/bash

RSERVER="10.216.25.44"
RCLIENT="10.216.25.43"
RCLIENT2="10.216.25.60"
SERVERIP="10.216.26.44"

SERVER_DIR="/home/hcho.ho/test/server/redis"
MEASURE_DIR="/home/hcho.ho/test/server/measures"
CLIENT_DIR="/home/hcho.ho/test/client/redis"
CLIENT2_DIR="/home/hcho.ho/test/client/redis"

#measures=("llc")
measures=("cpu" "throughput" "llc")

INSNUM=1
PARAL=50

LABEL="[ReTest]"

function info() {
	msg=$1
	echo "$LABEL $msg"
}

function cleanup_all() {
	info "Killing remote processes.."
	for (( i=0; i<3; i++)); do
		ssh -T $RCLIENT bash $CLIENT_DIR/killall.sh > /dev/null 2>&1
		ssh -T $RCLIENT2 bash $CLIENT2_DIR/killall.sh > /dev/null 2>&1
		ssh -T $RSERVER bash $SERVER_DIR/killall.sh > /dev/null 2>&1
		ssh -T $RSERVER bash $MEASURE_DIR/killall.sh > /dev/null 2>&1
		sleep 1
	done;
	info "Remote processes killed.."
}
function cleanup_server() {
	info "Killing remote server processes.."
	for (( i=0; i<3; i++)); do
		ssh -T $RSERVER bash $SERVER_DIR/killall.sh > /dev/null 2>&1
		sleep 1
	done;
	info "Remote server processes killed.."
}
function cleanup_measure() {
	info "Killing remote measure processes.."
	for (( i=0; i<3; i++)); do
		ssh -T $RSERVER bash $MEASURE_DIR/killall.sh > /dev/null 2>&1
		sleep 1
	done;
	info "Remote measure processes killed.."
}
function cleanup_client() {
	info "Killing remote client processes.."
	for (( i=0; i<3; i++)); do
		ssh -T $RCLIENT bash $CLIENT_DIR/killall.sh > /dev/null 2>&1
		ssh -T $RCLIENT2 bash $CLIENT2_DIR/killall.sh > /dev/null 2>&1
		sleep 1
	done;
	info "Remote client processes killed.."
}




function collect_results() {
	info "Start collecting results"
	now=`date "+%Y-%m-%d=%T"`
	name="$INSNUM-$PARAL-$now"
	mkdir -p ./results/$name
	scp -r $RCLIENT:$CLIENT_DIR/results ./results/$name/client > /dev/null 2>&1
	scp -r $RCLIENT2:$CLIENT2_DIR/results ./results/$name/client2 > /dev/null 2>&1
	scp -r $RSERVER:$MEASURE_DIR/results ./results/$name/server > /dev/null 2>&1
	info "Finish collecting results"
}

RUNSERVER=1
RUNCLIENT=1
RUNPOST=1

function start_test() {
	if [[ $RUNSERVER -ne 0 ]]; then
		cleanup_server

		# [1]
		info "Start setting up server NIC"
		ssh -T $RSERVER bash $SERVER_DIR/setuprss.sh -n $INSNUM -t on #> /dev/null 2>&1
		info "Finish setting up server NIC"

		# [2]
		info "Start running servers"
		ssh -T $RSERVER bash $SERVER_DIR/start.sh -p 10000 -n $INSNUM #> /dev/null 2>&1
		info "Finish running servers"
		
		# [3]
		info "Wait until server has data"
		ssh -T $RSERVER bash $SERVER_DIR/waitdata.sh -n $INSNUM #> /dev/null 2>&1
		info "Server now has data"

		# [4]
		info "Wait until server available"
		ssh -T $RCLIENT bash $CLIENT_DIR/pinguntil.sh -n $INSNUM #> /dev/null 2>&1
		info "Server is available"
	fi

	# [5]
	cleanup_measure
	info "Start starting measures"
	for measure in ${measures[@]}; do
		echo $measure
		ssh -T $RSERVER bash $MEASURE_DIR/measure-$measure.sh -o measure-$measure.dat > /dev/null 2>&1 &
	done;
	info "Finish starting measures"

	if [[ $RUNCLIENT -ne 0 ]]; then
		cleanup_client

		# [6]
		info "Starting running clients"
		CPARAL=$(($PARAL / 2))
		ssh -T $RCLIENT bash $CLIENT_DIR/start.sh -p 10000 -n $INSNUM -c $CPARAL -s $SERVERIP & #> /dev/null 2>&1
		ssh -T $RCLIENT2 bash $CLIENT2_DIR/start.sh -p 10000 -n $INSNUM -c $CPARAL -s $SERVERIP & #> /dev/null 2>&1
		info "Finish running clients"
		
		sleep 120
	fi

		
	if [[ $RUNPOST -ne 0  ]]; then
		info "Start killing everything"
		cleanup_all
		info "Finish killing everything"
		collect_results
	fi
	
}

function debug() {
	ssh -T $RSERVER bash $SERVER_DIR/test.sh
	ssh -T $RCLIENT bash $CLIENT_DIR/test.sh
}

while getopts n:c:k option
do
	case "$option" in
	n)
		INSNUM=$OPTARG;;
	c)
		PARAL=$OPTARG;;
	k)
		cleanup_all
		exit 0;;
	esac
done;

start_test
