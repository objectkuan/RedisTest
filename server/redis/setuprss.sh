#!/bin/sh

pushd `dirname "$0"` > /dev/null 2>&1
TEST_DIR=`pwd`
popd > /dev/null 2>&1

# Configurations
INSNUM=8
NTUPLE="on"
NTRULE=1
IFACE="eth5"
while getopts n:t:h option
do
	case "$option" in
	n)
		INSNUM=$OPTARG;;
	t)
		NTUPLE=$OPTARG;;
	h|\?)
		echo "Usage: $0 [-n instance_amount] [-t ntuple]"
		exit 0;;
	esac
done

# Reset RSS
cat /etc/modprobe.d/modprobe.conf | grep -v "RSS" > tmp
echo "options ixgbe RSS=$INSNUM,$INSNUM" >> tmp
mv tmp /etc/modprobe.d/modprobe.conf
rmmod ixgbe
modprobe ixgbe
sleep 5
$TEST_DIR/nic.sh -i $IFACE
echo "NTUPLE is $NTUPLE."
ethtool -K $IFACE ntuple $NTUPLE
if [[ x"$NTUPLE" == x"on" && $NTRULE -eq 1 ]]; then
	$TEST_DIR/setupntuple.sh -i $IFACE
	echo "NTUPLE Rules set."
fi
