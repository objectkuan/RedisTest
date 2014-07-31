#!/bin/bash

TESTS=(1 2 3 4)
for i in ${TESTS[@]}; do
	./sintest.sh -n 8 -c 500 -t $i
done;
