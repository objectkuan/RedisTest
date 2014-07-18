#!/bin/sh
COMMAND="echo 'error'"
while getopts c:h option
do
        case "$option" in
        c)
                COMMAND=$OPTARG;;
        h|\?)
                echo "Usage: $0 [-c command]"
                exit 0;;
        esac
done
sudo -u root -H sh -c "$COMMAND"
