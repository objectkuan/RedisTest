#!/bin/sh
ips=(`cat addr`)
for var in ${ips[@]};do
	./memtier_benchmark --server=$var --port=11210 --protocol=memcache_text --threads=100 --test-time=300  --out-file=result/$var >/dev/null 2>&1 &
	./memtier_benchmark --server=$var --port=11210 --protocol=memcache_text --threads=100 --test-time=300  --out-file=result/$var >/dev/null 2>&1 &
	./memtier_benchmark --server=$var --port=11210 --protocol=memcache_text --threads=100 --test-time=300  --out-file=result/$var >/dev/null 2>&1 &
	./memtier_benchmark --server=$var --port=11210 --protocol=memcache_text --threads=100 --test-time=300  --out-file=result/$var >/dev/null 2>&1 &
	./memtier_benchmark --server=$var --port=11210 --protocol=memcache_text --threads=100 --test-time=300  --out-file=result/$var >/dev/null 2>&1 &
done
