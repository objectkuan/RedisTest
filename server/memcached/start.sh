#!/bin/sh
LD_PRELOAD=./libsocket.so ./memcached -p 11210 -t 12 -l 10.216.26.44 -u root 2>&1 | tee ./log
