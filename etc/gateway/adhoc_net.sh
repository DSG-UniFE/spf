#!/bin/bash

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}


if test $# -ne 2
then
    echo "Error! Correct usage is:"
    echo "/path/to/$0 <INTERFACE> <IP_ADDRESS>"
    exit 1
fi

if ! `ifconfig $1 1> /dev/null`
then
    echo "Specified network interface $1 is not valid"
    exit 2
fi
IF_NAME=$1
shift

if ! valid_ip $1
then
    echo "Specified IP address $1 is not valid"
    exit 3
fi
IP_ADDR=$1
shift

RE=$(echo "\bID\b=(\w+)")
OS_INFO=`cat /etc/os-release`
if [[ $OS_INFO =~ $RE ]]
then
    DISTRO=`echo ${BASH_REMATCH[1]}`
    echo "Detected distro: $DISTRO"
else
    echo "Cannot detect the OS distro"
    exit 4
fi

case $DISTRO in
    ubuntu)
        sudo service networking stop
        echo "Stopped networking service"
        sudo service network-manager stop
        echo "Stopped network-manager service";;
    fedora)
        sudo service NetworkManager stop
        echo "Stopped NetworkManager service";;
    raspbian)
        sudo service networking stop
        echo "Stopped networking service";;
    *)
        echo "Distro $DISTRO not supported!"
        exit 5;;
esac

sudo ip link set $IF_NAME down
sudo iwconfig $IF_NAME mode ad-hoc essid DS_ADHOC channel 11
sudo ip link set $IF_NAME up
sudo ip addr add $IP_ADDR/24 dev $IF_NAME
