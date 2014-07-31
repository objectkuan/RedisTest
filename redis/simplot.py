#!/usr/bin/python
import os
import re
import matplotlib.pyplot as plot
from uplot import run_one_server_dir, run_one_client_dir

root = "results"

for test in os.listdir(root):
	server = "./" + root + "/" + test + "/server/"
	sresult = run_one_server_dir(server, test)



