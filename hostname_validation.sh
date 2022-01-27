#!/bin/bash

echo -e "This script is created to test whether the hostname and IP is seamless or not"

IFS=" " read -r -a ips_store <<< ""

endpoint="api.bni-ecollection.com"
echo -e "HOSTNAME: $endpoint"
counter=1
loopcounter=0
while true
do
    value_store=$(dig +short $endpoint)
    lists=""
    if [[ ! " ${ips_store[*]} " =~ " ${value_store} " ]]; then
        ips_store+=("${value_store}")
        length=${#ips_store[@]}
        for ((l = 0; l < length; l++))
        do
            lists+="${ips_store[$l]}\n"
        done

        if [[ "$loopcounter" != 0 ]]; then
        echo -e "IP CHANGED to $value_store\nIP LISTS:\n$lists"
        echo -e "IP CHANGED to $value_store\nIP LISTS:\n$lists" >> result.log
        fi
    fi
    for ((i = 0; i < ${#ips_store[@]}; i++))
    do
        ip="${ips_store[$i]}"
        status_code=$(curl -sI https://$ip --insecure | grep -Po "[0-9]{2,3}+" | head -n 1)
        echo "[$(date)] ${ips_store[$i]} $status_code"
        echo "[$(date)] ${ips_store[$i]} $status_code" >> result.log
    done

    if [ "$counter" -eq 9 ];then
    counter=1
    else
    ((counter=counter+1))
    fi
    ((loopcounter=loopcounter+1))
    sleep 0.5
done
