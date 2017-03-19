#!/bin/bash

HOSTS_CONF='hosts.conf'
DELIM=','
PORT_DELIM=';'
LOG_DIR='./logs'
HOSTS_LIST="${LOG_DIR}/hosts.txt"
REPORT_BIN='bash ./scan-report.sh -f'
SCAN_LOG="${LOG_DIR}/scan.$(date +%Y%m%d).log"
RAW_LOG="${LOG_DIR}/raw.$(date +%Y%m%d).log"
SCAN_REPORT="${LOG_DIR}/ports-scan.$(date +%Y%m%d).csv"

cd $(dirname "$0")
mkdir $LOG_DIR
awk -F$DELIM '{print $2}' $HOSTS_CONF > $HOSTS_LIST

# start scanning
sudo nmap -v -Pn --min-parallelism=100 --max-retries=3 -sS -pT:1-65535,U:1-65535 -oG $RAW_LOG -iL $HOSTS_LIST
$REPORT_BIN $RAW_LOG > $SCAN_LOG

function init_csv() {
    echo "HOST,IP,OPEN" > $SCAN_REPORT
}

function write_to_csv() {
    if [[ ! -z "$2" && ! -z "$3" ]]; then
        echo "$1,$2,$3" >> $SCAN_REPORT
    fi
}

function add_port() {
    if [ -z "$2" ]; then
        echo "$1"
    else
        echo "$2;$1"
    fi
}

function make_report() {
    local host=''
    local ip=''
    local status
    local open_report
    local closed_report
    local host_conf
    local open_ports_conf

    while read line; do
        if [[ $line == Host* ]]; then
            if [ "$(echo $line | grep 'Status')" != "" ]; then
                write_to_csv $host $ip $open_report
                ip=$(echo $line | awk '{print $2}')
                status=$(echo $line | awk '{print $5}')
                host_conf=$(grep $ip $HOSTS_CONF)
                host=$(echo $host_conf | awk -F$DELIM '{print $1}')
                if [ "$status" == "Up" ]; then
                    open_ports_conf=$(echo $host_conf | awk -F$DELIM '{print $3}')
                    open_report=''
                fi
            fi
        else
            port=$(echo $line | awk '{print $1}')    
            port_status=$(echo $line | awk '{print $2}')    
            if [ "$port_status" == "open" ]; then
                if [ "$(echo $open_ports_conf | grep -w $port)" == "" ]; then
                    open_report=$(add_port $port $open_report)
                fi
            # else
            #     if [ "$(echo $open_ports_conf | grep -w $port)" != "" ]; then
            #         closed_report=$(add_port $port $closed_report)
            #     fi
            fi
        fi
    done < $SCAN_LOG
    write_to_csv $host $ip $open_report
}

function send_report() {
    cat $SCAN_REPORT
    # title='Ports scan report'
    # body="Scan date: $(date)\n\n$(cat $SCAN_REPORT | tr -s ',;' '\t,' | sed ':a;N;$!ba;s/\n/\\n/g')"
    # echo -e "$body" | mail -s "$title" -r 'security@hello.com' sysadmin@hello.com
}

init_csv
make_report
send_report
