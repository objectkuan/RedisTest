#!/bin/bash
killall redis-benchmark
sleep 1
wait $!
