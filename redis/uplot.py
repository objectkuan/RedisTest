import re
import os
import matplotlib.pyplot as plot

target_dev = "eth5"

def run_one_client_dir(client_dir_name):
	# Total requests/s of one test case. 
	# Each is total_rps["OP"], e.g. total_rps["SADD"]
	total_rps = {}
	
	for name in os.listdir(client_dir_name):
		cfile = client_dir_name + name
		
		os.system("./removem.py " + cfile) # Remove ^M chars
		
		fhandle = open(cfile, 'r')
		lines = fhandle.readlines()
		for line in lines:
			m = re.match(r"^=+\s([^\s]+)\s=+", line)
			if m: # Operations
				op = m.group(1)
				if not total_rps.has_key(op):
					total_rps[op] = 0
			m = re.match(r"^([0-9\.]+)\srequests\sper\ssecond", line)
			if m: # Requests/s
				rps = m.group(1)
				total_rps[op] = total_rps[op] + float(rps)
		fhandle.close()
	return total_rps

def run_one_server_dir(server_dir_name, output_name):
	result = {}
	#cpu
	sfile = server_dir_name + "measure-cpu.dat"
	fhandle = open(sfile, 'r')
	lines = fhandle.readlines()
	seconds = [0]
	cpubusys = []
	for line in lines:
		if len(line) < 2:
			seconds.append(seconds[-1] + 1)
		m = re.match(r"^\d{2}:\d{2}:\d{2}\s[APM]{2}\s+([\d]{1,2})\s+([\d\.]+\s+){8}([\d\.]+)", line)
		if m:
			cpuid = int(m.group(1))
			cpuidle = float(m.group(3))
			if len(cpubusys) <= cpuid:
				cpubusys.append([0])
			cpubusys[cpuid].append(100 - cpuidle)
	#seconds = seconds[1 : len(seconds)]
	
	os.system('mkdir -p ./plot')
	plot.clf()
	plot.figure(figsize=(8,4))
	for i in range(0, len(cpubusys)):
		plot.plot(seconds, cpubusys[i])
	plot.savefig('./plot/' + output_name + '.png')

	#throughput
	sfile = server_dir_name + "measure-throughput.dat"
	fhandle = open(sfile, 'r')
	lines = fhandle.readlines()
	seconds = [0]
	throughputs = []
	total_throughput = 0
	amount_throughput = 0
	for line in lines:
		m = re.match(r"^\d{2}:\d{2}:\d{2}\s[APM]{2}\s+([^\s]+)\s+([\d\.]+)(\s+[\d\.]+){6}", line)
		if len(line) < 2:
			seconds.append(seconds[-1] + 1)
		if m:
			devname = m.group(1)
			rxpckps = m.group(2)
			if devname == target_dev:
				throughputs.append(rxpckps)
				if float(rxpckps) > 2000:
					total_throughput = total_throughput + float(rxpckps)
					amount_throughput = amount_throughput + 1
	fhandle.close()
	print "Average throughput of ", output_name, ": ", (total_throughput / amount_throughput), "packages per sec."
				
	os.system('mkdir -p ./plot/throughput')
	plot.clf()
	plot.figure(figsize=(8,4))
	if len(seconds) < len(throughputs):
		throughputs = throughputs[1:len(throughputs)]
	if len(seconds) > len(throughputs):
		seconds = seconds[1:len(seconds)]
	plot.plot(seconds, throughputs)
	plot.savefig('./plot/throughput/' + output_name + '.png')

	#llc
	sfile = server_dir_name + "measure-llc.dat"
	fhandle = open(sfile, 'r')
	lines = fhandle.readlines()
	llcs = {}
	for line in lines:
		m = re.match(r"\s*([\d,]*)\s+(LLC-[^\s]*)", line)
		if m:
			num = m.group(1).replace(",", "")
			name = m.group(2)
			llcs[name] = num
	fhandle.close()
	llcs["LLC-load-miss-rate"] = float(llcs["LLC-load-misses"]) * 100.0 / float(llcs["LLC-loads"])
	llcs["LLC-store-miss-rate"] = float(llcs["LLC-store-misses"]) * 100.0 / float(llcs["LLC-stores"])
	llcs["LLC-prefetch-miss-rate"] = float(llcs["LLC-prefetch-misses"]) * 100.0 / float(llcs["LLC-prefetches"])
	result["llc"] = llcs

	return result

