#!/usr/bin/python
import sys
import os

finname = sys.argv[1]
foutname = finname + ".bak"

fin = open(finname, "r")
fout = open(foutname, "w")

for line in fin.readlines():
	line = line.rstrip()
	line = line.replace("\r", "\n")
	fout.write(line + "\n")

fin.close()
fout.close()

os.system('mv ' + foutname + ' ' + finname)
