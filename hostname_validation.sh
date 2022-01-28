#!/bin/bash

echo -e "Script to test the hostname ip reliability."

IFS=" " read -r -a ips_store <<< ""

endpoint="api.bni-ecollection.com api.bni.co.id"
IFS=" " read -r -a endpoint <<< "$endpoint"
endpointlength=${#endpoint[@]}
for ((counter = 0; counter < endpointlength; counter++))
do
    echo -e "HOSTNAME: ${endpoint[@counter]}"

    # Log rotate for each endpoint
    logname="result.log"
    if [ -f "$logname" ]; then
        namerotator=$(ls $pwd | grep -Po "${logname}[\.0-9]*" | tail -n 1 | awk "{sub(/${logname}[\.]*/,\"\")}1")
        namerotator=$((namerotator+1))
        logname="$logname.$namerotator"
        echo $logname
    else
        logname="result.log"
    fi

    loopcounter=0
    while [ $loopcounter -lt 10 ]
    do
        value_store=$(dig +short ${endpoint[@counter]})
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
            echo -e "IP CHANGED to $value_store\nIP LISTS:\n$lists" >> $logname
            fi
        fi
        for ((i = 0; i < ${#ips_store[@]}; i++))
        do
            ip="${ips_store[$i]}"
            status_code=$(curl -sI https://$ip --insecure | grep -Po "[0-9]{2,3}+" | head -n 1)
            echo "[$(date)] ${ips_store[$i]} $status_code"
            echo "[$(date)] ${ips_store[$i]} $status_code" >> $logname
        done
        ((loopcounter=loopcounter+1))
        sleep 0.5
    done
done