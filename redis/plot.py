#!/usr/bin/python
import os
import re
import matplotlib.pyplot as plot
from uplot import run_one_server_dir, run_one_client_dir

root = "results"

run_server = True
run_client = False

# Total requests/s for all test cases.
# Each is rps_dict["INS-CON"], e.g. ddict["8-150"]
ins_arr = []
con_arr = []
rps_dict = {}
server_dict = {}

for test in os.listdir(root):
	server = "./" + root + "/" + test + "/server/"
	client = "./" + root + "/" + test + "/client/"

	ins = int(test.split('-')[0]) # instances
	con = int(test.split('-')[1]) # concurrency
	if not ins in ins_arr: ins_arr.append(ins)
	if not con in con_arr: con_arr.append(con)
	key = str(ins) + "-" + str(con)

	# Client benchmark data 
	if run_client:
		total_rps = run_one_client_dir(client)
		rps_dict[key] = total_rps
	
	# Server data 
	if run_server:
		server_result = run_one_server_dir(server, key)
		server_dict[key] = server_result

ins_arr.sort()
con_arr.sort()

# Results to show
if run_client:
	# Requests per second
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
				key = str(ins) + '-' + str(con)
				if rps_dict.has_key(key):
					print '%08.2f\t' % (rps_dict[key][op]),
				else:
					print '%08.2f\t' % 0,
			print ""

if run_server:
	# LLC
	llc_values = [ "L", "LM", "LMR", "S", "SM", "SMR", "P", "PM", "PMR" ]
	llc_formats = [15, 15, 6, 15, 15, 6, 15, 15, 6]
	print ""
	print "LLC Statistics"
	print "\t",
	for i in range(0, len(llc_values)):
		print ('%' + str(llc_formats[i]) + 's') % llc_values[i],
	print ""
	line_format = "{0:15s} {1:15s} {2:6.2f}"
	for ins in ins_arr:
		for con in con_arr:
			key = str(ins) + '-' + str(con)
			print key + "\t",
			if server_dict.has_key(key):
				llc = server_dict[key]["llc"]
				print line_format.format(llc["LLC-loads"].rjust(15), llc["LLC-load-misses"].rjust(15), llc["LLC-load-miss-rate"]),
				print line_format.format(llc["LLC-stores"].rjust(15), llc["LLC-store-misses"].rjust(15), llc["LLC-store-miss-rate"]), 
				print line_format.format(llc["LLC-prefetches"].rjust(15), llc["LLC-prefetch-misses"].rjust(15), llc["LLC-prefetch-miss-rate"])
