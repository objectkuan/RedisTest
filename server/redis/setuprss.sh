#!/bin/sh

pushd `dirname "$0"` > /dev/null 2>&1
TEST_DIR=`pwd`
popd > /dev/null 2>&1

# Configurations
INSNUM=8
NTUPLE="on"
while getopts n:t:h option
do
	case "$option" in
	n)
		INSNUM=$OPTARG;;
	t)
		NTUPLE=$OPTARG;;
	h|\?)
		echo "Usage: $0 [-p start_port] [-n instance_amount] [-t ntuple]"
		exit 0;;
	esac
done

# Reset RSS
cat /etc/modprobe.d/modprobe.conf | grep -v "RSS" > tmp
echo "options ixgbe RSS=$INSNUM,$INSNUM" >> tmp
mv tmp /etc/modprobe.d/modprobe.conf
rmmod ixgbe
modprobe ixgbe
$TEST_DIR/nic.sh -i eth5
ethtool -K eth5 ntuple $NTUPLE
