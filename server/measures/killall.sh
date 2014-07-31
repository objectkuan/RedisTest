#!/bin/bash
killall sar
for (( c=1; c<=5; c++ )) do
    killall -2 perf
    sleep 1
done
killall perf
