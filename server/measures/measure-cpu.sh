#!/bin/bash

PWD=`dirname "$0"`
cd $PWD

TIME=""
INTERVAL=1
OUTPUT=

while getopts o:t:i:h option
do
    case "$option" in
        o)
            OUTPUT=$OPTARG;;
        t)
            TIME=$OPTARG;;
        i)
            INTERVAL=$OPTARG;;
        h|\?)
            echo "Usage: $0 [-t time] [-o output]"
            exit 0;;
    esac
done

if [[ "$OUTPUT" = "" ]]; then
    sar -P ALL -u ALL $INTERVAL $TIME
#    pids[${#pids[@]}]=$!
else
    mkdir -p results
    sar -P ALL -u ALL $INTERVAL $TIME > results/$OUTPUT
#    pids[${#pids[@]}]=$!
fi

#for pid in ${pids[@]}; do
#	wait $pid
#done;
