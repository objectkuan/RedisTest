#!/bin/bash

TESTED_DRIVERS=("igb" "ixgbe" "bnx2" "tg3")
TESTED_MODELS=(
    # igb
    "Intel Corporation 82576 Gigabit Network Connection (rev 01)"
    "Intel Corporation I350 Gigabit Network Connection (rev 01)"
    # ixgbe
    "Intel Corporation 82599EB 10-Gigabit SFI/SFP+ Network Connection (rev 01)"
    "Intel Corporation 82599ES 10-Gigabit SFI/SFP+ Network Connection (rev 01)"
    # tg3
    "Broadcom Corporation NetXtreme BCM5720 Gigabit Ethernet PCIe"
    "Broadcom Corporation NetXtreme BCM5761 Gigabit Ethernet PCIe (rev 10)"
    # bnx2
    "Broadcom Corporation NetXtreme II BCM5708 Gigabit Ethernet (rev 12)"
    "Broadcom Corporation NetXtreme II BCM5709 Gigabit Ethernet (rev 20)"
)

if tput colors > /dev/null; then
    RED='\e[0;31m'
    YELLOW='\e[1;33m'
    GREEN='\e[0;32m'
    NC='\e[0m'
else
    RED=''
    YELLOW=''
    NC=''
fi

function print_usage() {
    echo "Usage: $0 -i <NIC to be used> [ -f <RFS_ENABLED> ] [ -p <RPS_ENABLED> ]"
    exit 0
}

function err_msg() {
    local msg=$1
    echo -e "$RED[Error] $msg $NC"
    exit 1
}

function warn_msg() {
    local msg=$1
    echo -e "$YELLOW[Warning] $msg $NC"
}

function info_msg() {
    local msg=$1
    echo -e "$msg $NC"
}

function tested() {
    local iface=$1
    local model=$2

    for m in "${TESTED_MODELS[@]}"; do
	if [[ "$model" == "$m" ]]; then
	    return 0
	fi
    done

    return 1
}

function intr_pattern() {
    local iface=$1
    local driver=$2
    case $driver in
	igb|ixgbe)
	    echo $iface-TxRx;;
	bnx2|tg3)
	    echo $iface;;
    esac
}

function hardware_queues() {
    local driver=$1
    local intrs=$2
    case $driver in
	igb|ixgbe|bnx2)
	    echo $intrs;;
	tg3)
	    echo $((intrs-1));;
    esac
}

function intr_list() {
    local iface=$1
    local driver=$2

    case $driver in
	igb|ixgbe|bnx2|tg3)
	    intr_pattern $IFACE $DRIVER | xargs -i grep {} /proc/interrupts | grep -o "^ *[0-9]*" | xargs -i echo {};;
    esac
}

function cpuid_to_mask() {
    local id=$1
    echo $((10**(id/4) * 2**(id%4)))
}

##################################################
# Main part starts here

if [[ ! "$UID" = 0 ]]; then
    err_msg "This script must be run as ROOT"
fi

RFS_ENABLED=0
RPS_ENABLED=0
XPS_ENABLED=0
INTR_AFF=1

while getopts i:f:p:x:h option
do
    case "$option" in
        i)
            IFACE=$OPTARG;;
	f)
	    RFS_ENABLED=$OPTARG;;
	p)
	    RPS_ENABLED=$OPTARG;;
	x)
	    XPS_ENABLED=$OPTARG;;
        h|\?)
	    print_usage;;
    esac
done

if [[ -z $IFACE ]]; then
    print_usage
fi

# Sanity checks on the interface given
if ! ifconfig $IFACE > /dev/null 2>&1; then
    err_msg "$IFACE not available... please double check"
fi
if ! ip link show $IFACE | grep UP > /dev/null 2>&1; then
    err_msg "$IFACE not up... please double check"
fi

# Check the driver of the interface
DRIVER=$(ethtool -i $IFACE 2>/dev/null | grep driver | egrep -o "[a-zA-Z0-9_]+$")
if [[ -z $DRIVER ]] || [[ ! -n "${TESTED_DRIVERS[$DRIVER]}" ]]; then
    err_msg "We have not tested on $IFACE (driver: $DRIVER) and not sure how to configure it yet. Consider choosing another?"
fi

# Check the model of the interface
BUS=$(ethtool -i $IFACE 2>/dev/null | grep bus-info | egrep -o "[0-9a-f]+:[0-9a-f]+\.[0-9a-f]+")
MODEL=$(lspci | grep $BUS | sed "s/$BUS //g" | sed "s/Ethernet controller: //g")
if ! tested "$IFACE" "$MODEL"; then
    warn_msg "We have not tested specifically on \"$MODEL\""
    warn_msg "We'll try configuring $IFACE in the way we have done on NICs supported by $DRIVER..."
fi

INTRS=$(intr_pattern $IFACE $DRIVER | xargs -i grep {} /proc/interrupts | wc -l)
CORES=$(grep processor /proc/cpuinfo | wc -l)
TX_QUEUES=$(ls /sys/class/net/$IFACE/queues | grep tx | wc -l)
RX_QUEUES=$(ls /sys/class/net/$IFACE/queues | grep rx | wc -l)
HW_QUEUES=$(hardware_queues $DRIVER $INTRS)

info_msg "Configuring $IFACE..."
info_msg "    Bus info: $BUS"
info_msg "    Model: $MODEL"
info_msg "    Driver: $DRIVER"
info_msg "    Number of..."
info_msg "        cores: $CORES"
info_msg "        interrupts: $INTRS"
info_msg "        software Tx queues: $TX_QUEUES"
info_msg "        software Rx queues: $RX_QUEUES"
info_msg "        hardware queues: $HW_QUEUES"

# Allow 3000 interrupts at most per second
ethtool -C $IFACE rx-usecs 333 > /dev/null 2>&1
info_msg "    Interrupt throttle rate: 3000"

# Use XPS to set affinities of Tx queues
# Note: This is only done when we have more Tx queues than cores.
if [[ ( $TX_QUEUES -ge $CORES ) && ($XPS_ENABLED == 1) ]]; then
    for i in $(seq 0 $((CORES-1))); do
	cpuid_to_mask $((i%CORES)) | xargs -i echo {} > /sys/class/net/$IFACE/queues/tx-$i/xps_cpus
    done
    info_msg "    XPS enabled"
else 
    info_msg "    XPS disabled"
fi

# Enable RPS if number of cores and hardware cores are not equal
if [[ (! $HW_QUEUES == $CORES) && ($RPS_ENABLED == 1) ]]; then
    for i in /sys/class/net/$IFACE/queues/rx-*; do
	printf "%x\n" $((2**CORES-1)) | xargs -i echo {} > $i/rps_cpus;
    done
    info_msg "    RPS enabled"
else
    for i in /sys/class/net/$IFACE/queues/rx-*; do
	echo 0 > $i/rps_cpus;
    done
    info_msg "    RPS disabled"
fi

if [[ $RFS_ENABLED == 1 ]]; then
    echo 32768 > /proc/sys/net/core/rps_sock_flow_entries
    for i in /sys/class/net/$IFACE/queues/rx-*; do
	echo $((32768 / $RX_QUEUES)) > $i/rps_flow_cnt
    done
    info_msg "    RFS enabled"
else 
    echo 0 > /proc/sys/net/core/rps_sock_flow_entries
    for i in /sys/class/net/$IFACE/queues/rx-*; do
	echo 0 > $i/rps_flow_cnt
    done
    info_msg "    RFS disabled"
fi

# Set interrupt affinities
if [ $INTR_AFF -eq 1 ]; then
	i=0
	intr_list $IFACE $DRIVER | while read irq; do
	cpuid_to_mask $((i%CORES)) | xargs -i echo {} > /proc/irq/$irq/smp_affinity
	    i=$((i+1))
	done
fi

# Enlarge open file limits
ulimit -n 65536

# info_msg "Allow more time-wait socket buckets..."
# sysctl -w net.ipv4.tcp_max_tw_buckets=180000 > /dev/null 2>&1

#info_msg "Disable nf_conntrack..."
#iptables -A PREROUTING -p tcp -j NOTRACK > /dev/null 2>&1
#iptables -A PREROUTING -p udp -j NOTRACK > /dev/null 2>&1
#iptables -t raw -A OUTPUT -p tcp -j NOTRACK > /dev/null 2>&1
#iptables -t raw -A OUTPUT -p udp -j NOTRACK > /dev/null 2>&1
service iptables stop

#if ps aux | grep irqbalance | grep -v grep; then
#    info_msg "Disable irqbalance..."
#    # XXX Do we have a more moderate way to do this?
#    killall irqbalance > /dev/null 2>&1
#fi

ethtool -K eth5 gro off
info_msg "${GREEN}Fastsocket has successfully configured on $IFACE$NC"
