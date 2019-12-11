#!/bin/bash

# Subnetwork IP scanner
# Matthias Tornay - 15/07/19

# Usage : sudo ./scan_host_ip.sh [-t timeout] [-b broadcast]

# TO DO LIST:
# - write second level scan (currently not well implemented)
# - add an option to save known IP and their lantencies to
#   search them more precisely by adaptating the TIMEOUT
# - multi-thread / optimization of performance

# Set ping timeout in seconds
TIMEOUT=0.1

# Set to 0 for enable broadcast pinging
BROADCAST_PINGING=1

# Set subnetwork scan level (2 may increase WIDELY time and CPU usage !)
SUBNET_LEVEL=1

usage()  {

	echo "Invalid argument"
	echo "Usage : sudo ./scan_host_ip.sh [-t timeout] [-b broadcast]"

	exit

}

while [ -n "$1" ]; do
    case "$1" in
	    -t)
		    case $2 in
		    	''|*[!0-9.]*) usage ;;
		    	*) TIMEOUT=$2 ;;
			esac
			;;
	 
	    -b)
	        case "$2" in
			    true|1) BROADCAST_PINGING=0 ;;
			    false|0) BROADCAST_PINGING=1 ;;
			    *) usage ;;
			esac
	        shift
	        ;;

	    -l)
			case "$2" in
				1) SUBNET_LEVEL=1 ;;
				2) SUBNET_LEVEL=2 ;;
				*) usage ;;
	 		esac
	 		shift
	 		;;

	    --)
	        shift
	        break
	        ;;
	
		#*) usage ;;
    esac
    shift
done

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit; fi

gateway=$(route -n | sed "3q;d" | awk '{print $2}')

#if [ "$SUBNET_LEVEL" -eq 1 ]
#then
#	_level_state="XXX"
#	IFS=. read -r ip1 ip2 ip3 <<< "$gateway"
#	IFS=. read -r mask1 mask2 mask3 <<< "255.255.255.0"
#	mask=$(printf "%d.%d.%d" "$((ip1 & mask1))" "$((ip2 & mask2))" "$((ip3 & mask3))")
#else
#	_level_state="XXX.YYY"
#	IFS=. read -r ip1 ip2 <<< "$gateway"
#	IFS=. read -r mask1 mask2 <<< "255.255.0.0"
#	mask=$(printf "%d.%d" "$((ip1 & mask1))" "$((ip2 & mask2))")
#fi
#
#
#
mask="192.168.0"
echo -e "Scanning "$mask"."$_level_state" subnetwork (0 -> 255)"
echo "Ping timeout is set to "$TIMEOUT" s"

if [ "$BROADCAST_PINGING" -eq 1 ]; then _broadcast_state=" not"; fi
echo "Broadcast pinging is"$_broadcast_state" enable"

echo -e "\nResponding devices :"

echo -e "\n-- NMAP scan"
devices=$(sudo nmap -sL $gateway/24 -T4 | grep '(' | tail -n +2 | head -n -1 | grep -oP '(?<= for ).*')
echo $devices | tr ') ' ')\n'

echo -e "\n-- PING scan"
touch .pingfile

x=$BROADCAST_PINGING
if [ "$SUBNET_LEVEL" -eq 1 ]; then
	while [ $x -le $(( 254 - "$BROADCAST_PINGING" )) ]
	do
		sudo timeout $TIMEOUT ping -b -w 1 -c 1 "$mask"."$x" > .pingfile
		_ip=$(cat .pingfile | grep -oP '.*(?<=time=).*' | awk '{print $4}' | tr -d ':')
		_latency=$(cat .pingfile | grep -oP '(?<=time=).*')

		if [ "${#_latency}" -ne 0 ]; then echo ""$_ip" responded in "$_latency""; fi
		((x++))
	done
fi
#elif [ "$SUBNET_LEVEL" -eq 2 ]; then
#	while [ $y -le $(( 254 - "$BROADCAST_PINGING" )) ]
#	do
#		while [ $x -le $(( 254 - "$BROADCAST_PINGING" )) ]
#		do
#			sudo timeout $TIMEOUT ping -b -w 1 -c 1 "$mask""$x" > .pingfile
#		done
#	done
#
#fi

