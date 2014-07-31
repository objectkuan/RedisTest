#!/bin/bash
#134 ... 146
#echo 1 > /proc/irq/134/smp_affinity
#echo 4 > /proc/irq/135/smp_affinity
#echo 10 > /proc/irq/136/smp_affinity
#echo 40 > /proc/irq/137/smp_affinity
#echo 100 > /proc/irq/138/smp_affinity
#echo 400 > /proc/irq/139/smp_affinity

cat /proc/interrupts | grep eth5 | awk -F'[ :]' '{print $2}' | xargs -i cat /proc/irq/{}/smp_affinity

#cgexec -g cpuset:redis_2  ./redis-server configs/config-10000
#cgexec -g cpuset:redis_4  ./redis-server configs/config-10001
#cgexec -g cpuset:redis_6  ./redis-server configs/config-10002
#cgexec -g cpuset:redis_8  ./redis-server configs/config-10003
#cgexec -g cpuset:redis_10  ./redis-server configs/config-10004
#cgexec -g cpuset:redis_12  ./redis-server configs/config-10005

cgexec -g cpuset:redis_1  ./redis-server configs/config-10000
cgexec -g cpuset:redis_3  ./redis-server configs/config-10001
cgexec -g cpuset:redis_5  ./redis-server configs/config-10002
cgexec -g cpuset:redis_7  ./redis-server configs/config-10003
cgexec -g cpuset:redis_9  ./redis-server configs/config-10004
cgexec -g cpuset:redis_11  ./redis-server configs/config-10005
