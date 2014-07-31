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
    /root/bin/perf stat -e LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses,LLC-prefetches,LLC-prefetch-misses -p `pgrep -d',' redis-server`
else
    mkdir -p results
    /root/bin/perf stat -e LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses,LLC-prefetches,LLC-prefetch-misses -p `pgrep -d',' redis-server` > results/$OUTPUT 2>&1
fi

