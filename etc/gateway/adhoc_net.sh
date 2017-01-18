sudo service networking stop
sudo service network-manager stop
sudo ip link set wlp2s0 down
sudo iwconfig wlp2s0 mode ad-hoc essid DS_ADHOC channel 11
sudo ip link set wlp2s0 up
sudo ip addr add 192.168.1.10/24 dev wlp2s0
