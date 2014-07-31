#!/usr/bin/python
import os
import re
import matplotlib.pyplot as plot

root = "result-5"

run_server = True
run_client = True


# Total requests/s for all test cases.
# Each is ddict["INS-CON"], e.g. ddict["8-150"]
ddict = {}

for test in os.listdir(root):
	server = "./" + root + "/" + test + "/server/"
	client = "./" + root + "/" + test + "/client/"

	ins = test.split('-')[0] # instances
	con = test.split('-')[1] # concurrency
		
	#######################
	# Client benchmark data 
	#######################
	if run_client:
		# Total requests/s of one test case. 
		# Each is total_rps["OP"], e.g. total_rps["SADD"]
		total_rps = {}
		
		for name in os.listdir(client):
			cfile = client + name
			
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

		ddict[ins + "-" + con] = { }
		ddict[ins + "-" + con] = total_rps
	
	#######################
	# Server data 
	#######################
	if run_server:
		sfile = server + "measure-cpu.dat"
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
		seconds = seconds[1 : len(seconds)]
		
		os.system('mkdir -p ./plot')
		plot.clf()
		plot.figure(figsize=(8,4))
		for i in range(0, len(cpubusys)):
			plot.plot(seconds, cpubusys[i])
		plot.savefig('./plot/' + ins + '-' + con + '.png')

if run_client:
	ins_arr = [1, 2, 4, 8, 12]
#	con_arr = [150, 200, 400, 600, 800, 1000]
	con_arr = [150, 200, 400]

	for op in total_rps.keys():
		print "\n"
		print op
		print "\t",
		for con in con_arr:
			print str(con) + "\t\t",
		print ""
		for ins in ins_arr:
			print str(ins) + "\t",
			for con in con_arr:
				print '%08.2f\t' % (ddict[str(ins) + '-' + str(con)][op]),
			print ""


