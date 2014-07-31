#!/bin/sh

pushd `dirname "$0"` > /dev/null 2>&1
TEST_DIR=`pwd`
popd > /dev/null 2>&1

# Configurations
INSNUM=8
NTUPLE="on"
NTRULE=1
IFACE="eth5"
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
		echo "Usage: $0 [-n instance_amount] [-t ntuple]"
		exit 0;;
	esac
done

echo $INSNUM

# Reset RSS
cat /etc/modprobe.d/modprobe.conf | grep -v "RSS" > /etc/modprobe.d/tmp
echo "options ixgbe RSS=$INSNUM,$INSNUM" >> /etc/modprobe.d/tmp
mv /etc/modprobe.d/tmp /etc/modprobe.d/modprobe.conf

# Reprobe ixgbe driver
rmmod ixgbe
modprobe ixgbe
sleep 5

$TEST_DIR/nic.sh -i $IFACE -p $RPS_ENABLED -f $RFS_ENABLED

# Setup NUTPLE
echo "NTUPLE is $NTUPLE."
ethtool -K $IFACE ntuple $NTUPLE
if [[ x"$NTUPLE" == x"on" && $NTRULE -eq 1 ]]; then
	$TEST_DIR/setupntuple.sh -i $IFACE
	echo "NTUPLE Rules set."
fi
