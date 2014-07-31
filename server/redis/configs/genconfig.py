#!/usr/bin/python
import sys
import argparse
import os

config = {
	'port':			'6379',
	'appendonly':		'yes',
	'appendfilename':	'appendonly.aof',
	'appendfsync':		'everysec',
}

parser = argparse.ArgumentParser(description='Configuration values for Redis')
parser.add_argument('--port', action='store',
		default="6379", help='a port to listen (default: 6379)')
parser.add_argument('--appendonly', action='store',
		default="yes", help='whether to append the file only (default: yes)')
parser.add_argument('--appendfsync', action='store',
		default="everysec", help='the way to call fsync (default: everysec)')
args = parser.parse_args()

config['port'] = args.port
config['appendfilename'] = 'appendonly.aof'
config['appendonly'] = args.appendonly
config['appendfsync'] = args.appendfsync
config['dbfilename'] = 'r' + args.port + ".rdb"
#config['libredis'] = './libredis.so.2.4.20.3.' + config['port']
config['libredis'] = './libredis.so.2.4.20.3'

config_file_name = 'config-' + config['port']
os.system('cat redis.conf.tmpl > ' + config_file_name)
f = open(config_file_name, 'a')
for k, v in config.iteritems():
	f.write(k + " " + v + "\n")
f.close()




