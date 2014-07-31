#!/bin/bash
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
function intr_list() {
    local iface=$1
    local driver=$2

    case $driver in
        igb|ixgbe|bnx2|tg3)
            intr_pattern eth2 ixgbe | xargs -i grep {} /proc/interrupts | grep -o "^ *[0-9]*" | xargs -i echo {};;
    esac
}

function cpuid_to_mask() {
    local id=$1
    echo $((10**(id/4) * 2**(id%4)))
}
# Set interrupt affinities
i=0
intr_list eth2 ixgbe | while read irq; do
    cpuid_to_mask $((i%24)) | xargs -i echo {} > /proc/irq/$irq/smp_affinity
    i=$((i+1))
done
