#!/bin/bash

##########################################
# Configuration and parameters
##########################################
INSNUM=1
PARAL=50
DO_TEST=1
JUST_CLEAN=0
while getopts n:c:t:k option
do
	case "$option" in
	n)
		INSNUM=$OPTARG;;
	c)
		PARAL=$OPTARG;;
	t)
		DO_TEST=$OPTARG;;
	k)
		JUST_CLEAN=1;;
	esac
done;

source config.sh


##########################################
# Functions to print
##########################################
LABEL="[ReTest]"
function info() {
	msg=$1
	echo "$LABEL $msg"
}

##########################################
# Functions to execute remote commands
# The executions are performed with ROOT
##########################################
function rserver_call() {
	_command=$1
	ssh -T $RSERVER "bash $SERVER_DIR/rootstart.sh -c \"$_command\""
}
function rserver_call_d() {
	_command=$1
	ssh -T $RSERVER "bash $SERVER_DIR/rootstart.sh -c \"$_command\"" &
}
function rclient_call() {
	_command=$1
	ssh -T $RCLIENT "bash $CLIENT_DIR/rootstart.sh -c \"$_command\"" &
}
function rclient2_call() {
	_command=$1
	ssh -T $RCLIENT2 "bash $CLIENT2_DIR/rootstart.sh -c \"$_command\"" &
}

##########################################
# Functions to kill remote processes
##########################################
function cleanup_all() {
	info "Killing remote processes.."
	for (( i=0; i<3; i++)); do
		rclient_call "$CLIENT_DIR/killall.sh" /dev/null 2>&1 &
		rclient2_call "$CLIENT2_DIR/killall.sh" > /dev/null 2>&1 &
		rserver_call "$SERVER_DIR/killall.sh" > /dev/null 2>&1 &
		rserver_call "$MEASURE_DIR/killall.sh" > /dev/null 2>&1 &
		#ssh -T $RCLIENT bash $CLIENT_DIR/killall.sh > /dev/null 2>&1 &
		#ssh -T $RCLIENT2 bash $CLIENT2_DIR/killall.sh > /dev/null 2>&1 &
		#ssh -T $RSERVER bash $SERVER_DIR/killall.sh > /dev/null 2>&1 &
		#ssh -T $RSERVER bash $MEASURE_DIR/killall.sh > /dev/null 2>&1 &
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


##########################################
# Functions to collect testing results
##########################################
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

if [ $JUST_CLEAN -eq 1 ]; then
	cleanup_all
	exit 0
fi

RUNSERVER=1
RUNCLIENT=1
RUNPOST=1

function start_test() {
	if [[ $RUNSERVER -ne 0 ]]; then
		cleanup_server

		# [1]
		info "Start setting up server NIC"
		rserver_call "$SERVER_DIR/setuprss.sh -n $INSNUM -t $NTUPLE -f $RFS_ENABLED -p $RPS_ENABLED"
		#ssh -T $RSERVER bash $SERVER_DIR/setuprss.sh -n $INSNUM #> /dev/null 2>&1
		info "Finish setting up server NIC"

		# [2]
		info "Start running servers"
		rserver_call "$SERVER_DIR/start.sh -p 10000 -n $INSNUM"
		#ssh -T $RSERVER bash $SERVER_DIR/start.sh -p 10000 -n $INSNUM > /dev/null 2>&1
		pids[${#pids[@]}]=$!
		info "Finish running servers"
		
		# [3]
		info "Wait until server has data"
		ssh -T $RSERVER bash $SERVER_DIR/waitdata.sh #> /dev/null 2>&1
		info "Server now has data"

		# [4]
		info "Wait until server available"
		ssh -T $RCLIENT bash $CLIENT_DIR/pinguntil.sh -n $INSNUM -s $SERVERIP #> /dev/null 2>&1
		info "Server is available"

		# [5]
		info "Start starting measures"
		for measure in ${measures[@]}; do
			rserver_call_d "$MEASURE_DIR/measure-$measure.sh -o measure-$measure.dat"
			#ssh -T $RSERVER bash $MEASURE_DIR/measure-$measure.sh -o measure-$measure.dat > /dev/null 2>&1 &
		done;
		info "Finish starting measures"
	fi

	if [[ $RUNCLIENT -ne 0 ]]; then
		# [6]
		info "Starting running clients"
		CPARAL=$(($PARAL / 2))
		rclient_call "$CLIENT_DIR/start.sh -p 10000 -n $INSNUM -c $CPARAL -s $SERVERIP"
		rclient2_call "$CLIENT2_DIR/start.sh -p 10000 -n $INSNUM -c $CPARAL -s $SERVERIP"
		#ssh -T $RCLIENT bash $CLIENT_DIR/start.sh -p 10000 -n $INSNUM -c $CPARAL -s $SERVERIP & #> /dev/null 2>&1
		#ssh -T $RCLIENT2 bash $CLIENT2_DIR/start.sh -p 10000 -n $INSNUM -c $CPARAL -s $SERVERIP & #> /dev/null 2>&1
		info "Finish running clients"
		
		sleep $RECORD_TIME
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


start_test
