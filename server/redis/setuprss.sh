#!/bin/sh

pushd `dirname "$0"` > /dev/null 2>&1
TEST_DIR=`pwd`
popd > /dev/null 2>&1

# Configurations
INSNUM=8
NTUPLE="on"
RFS_ENABLED=0
RPS_ENABLED=0
while getopts n:t:f:p:h option
do
	case "$option" in
	n)
		INSNUM=$OPTARG;;
	t)
		NTUPLE=$OPTARG;;
        f)
		RFS_ENABLED=$OPTARG;;
        p)
		RPS_ENABLED=$OPTARG;;
	h|\?)
		echo "Usage: $0 [-p start_port] [-n instance_amount] [-t ntuple]"
		exit 0;;
	esac
done

# Reset RSS
cat /etc/modprobe.d/modprobe.conf | grep -v "RSS" > /etc/modprobe.d/tmp
echo "options ixgbe RSS=$INSNUM,$INSNUM" >> /etc/modprobe.d/tmp
mv /etc/modprobe.d/tmp /etc/modprobe.d/modprobe.conf
rmmod ixgbe
modprobe ixgbe
$TEST_DIR/nic.sh -i eth6 -p $RPS_ENABLED -f $RFS_ENABLED
ethtool -K eth6 ntuple $NTUPLE
