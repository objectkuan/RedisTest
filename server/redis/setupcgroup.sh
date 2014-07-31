#!/bin/sh
cpus=(0 1 2 3 4 5 6 7 8 9 10 11)
mems=(0 1 0 1 0 1 0 1 0 1 0 1)
#cpus=(0 2 4 6 8 10 1 3 5 7 9 11)
#mems=(0 0 0 0 0 0 1 1 1 1 1 1)
#cpus=(13 14 15 16 17 18 19 20)
#mems=( 1  1  1  1  1  1  1  1)
reds=(1 2 3 4 5 6 7 8 9 10 11 12)

service cgconfig start

mkdir /my_cgroup
mount -t cgroup -o cpuset cpuset /my_cgroup/

mkdir /my_cgroup/base_task
mkdir /my_cgroup/redis_1
mkdir /my_cgroup/redis_2
mkdir /my_cgroup/redis_3
mkdir /my_cgroup/redis_4
mkdir /my_cgroup/redis_5
mkdir /my_cgroup/redis_6
mkdir /my_cgroup/redis_7
mkdir /my_cgroup/redis_8
mkdir /my_cgroup/redis_9
mkdir /my_cgroup/redis_10
mkdir /my_cgroup/redis_11
mkdir /my_cgroup/redis_12

echo 0 > /my_cgroup/base_task/cpuset.cpus
echo 0 > /my_cgroup/base_task/cpuset.mems

j=0
for i in ${cpus[@]}; do
	echo ${cpus[$j]} > /my_cgroup/redis_${reds[$j]}/cpuset.cpus
	echo ${mems[$j]} > /my_cgroup/redis_${reds[$j]}/cpuset.mems
	cat /my_cgroup/redis_${reds[$j]}/cpuset.cpus
	cat /my_cgroup/redis_${reds[$j]}/cpuset.mems
	j=$(($j+1))
done;
