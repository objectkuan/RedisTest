#!/bin/sh
killall redis-server
sleep 1
wait $!

