#!/bin/bash

function usage {
	echo "Usage: $1 [-f nmap.grepable] [-i IP] [-p port] [-s service] [-P protocol] [-a]"
	echo "  -a: outputs matching IP addresses only"
}

db=""
ip=""
port=""
proto=""
addressonly=""
while getopts "f:i:p:P:s:a" OPT; do
	case $OPT in
		f) db=$OPTARG;;
		i) ip=$OPTARG;;
		p) port=$OPTARG;;
		s) service=$OPTARG;;
		P) proto=$OPTARG;;
		a) addressonly=true;;
		*) usage $0; exit;;
	esac
done

if [[ -z $db ]]; then 
	# check if nmap-db.grep exists
	if [[ -f ${HOME}/nmap-db.grep ]]; then 
		db=${HOME}/nmap-db.grep
	else
		usage $0
		exit
	fi
fi

if [[ ! -z $ip ]]; then # search by IP
	r=$(grep -w "$ip" "$db" | grep -v ^# | sed 's/Ports: /\'$'\n/g' |  tr '/' '\t' | tr ',' '\n' | sed 's/^ //g' | grep -v "Status:" | sed 's/Ignored State.*$//')

elif [[ ! -z $port ]]; then # search by port number
	r=$(grep -w -E -e "($port)\/open" "$db" | grep -v ^# | sed 's/Ports: /\'$'\n/g' |  tr '/' '\t' | tr ',' '\n' | sed 's/^ //g' | grep -v "Status:" | grep -E -e "Host: " -e "^(${port})" | sed 's/Ignored State.*$//')

elif [[ ! -z $service ]]; then # search by service name
	r=$(grep -w -E -i -e "($service)" "$db" | grep -v ^# | sed 's/Ports: /\'$'\n/g' |  tr '/' '\t' | tr ',' '\n' | sed 's/^ //g' | grep -v "Status:" | grep -i -E -e "Host: " -e "(${service})" | sed 's/Ignored State.*$//')
elif [[ ! -z $proto ]]; then
	r=$(grep -w -E -i -e "($proto)" "$db" | grep -v ^# | sed 's/Ports: /\'$'\n/g' |  tr '/' '\t' | tr ',' '\n' | sed 's/^ //g' | grep -v "Status:" | grep -i -E -e "Host: " -e "(${proto})" | sed 's/Ignored State.*$//')
else
	r=$(cat "$db" | grep -v ^# | sed 's/Ports: /\'$'\n/g' | tr '/' '\t' | tr ',' '\n' | sed 's/^ //g' | sed 's/Ignored State.*$//')
fi

if [[ $addressonly ]]; then # output only IPs/hostnames
	echo -e "$r" | grep "Host:" | awk {'print $2'}
else
	echo -e "$r"
fi
