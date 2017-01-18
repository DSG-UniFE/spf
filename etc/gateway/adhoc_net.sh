#!/bin/bash
RE1=$(echo "\bID\b=(\w+)")
OS_INFO=`cat /etc/os-release`
if [[ $OS_INFO =~ $RE1 ]]
then
    DISTRO=`echo ${BASH_REMATCH[1]}`
    echo "Detected distro: $DISTRO"
else
    echo ${BASH_REMATCH[1]}
    echo "Cannot detect the OS distro"
    exit 1
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
        echo "Stopped networking service"
    *)
        echo "Distro $DISTRO not supported!"
        exit 2;;
esac

sudo ip link set wlp3s0 down
sudo iwconfig wlp3s0 mode ad-hoc essid DS_ADHOC channel 11
sudo ip link set wlp3s0 up
sudo ip addr add 192.168.1.9/24 dev wlp3s0
