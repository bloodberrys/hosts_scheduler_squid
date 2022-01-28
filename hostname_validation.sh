#!/bin/bash

echo -e "Script to test the hostname ip reliability."

mkdir results
IFS=" " read -r -a ips_store <<< ""

endpoint="api.bni-ecollection.com api.bni.co.id dev.bni-ecollection.com apidev.bni.co.id aping-ideal.dbs.com aping.dbs.id apingid.wlb.dbs.id api.btpn.com api-mt.thunes.com api.danamon.co.id api.mailgun.net"
IFS=" " read -r -a endpoint <<< "$endpoint"
endpointlength=${#endpoint[@]}
for ((counter = 0; counter < endpointlength; counter++))
do
    # Log rotate for each endpoint
    logname="result.log"
    if [ -f "results/$logname" ]; then
        namerotator=$(ls $pwd/results | grep -Po "${logname}[\.0-9]*" | tail -n 1 | awk "{sub(/${logname}[\.]*/,\"\")}1")
        namerotator=$((namerotator+1))
        logname="$logname.$namerotator"
        echo $logname
    else
        logname="result.log"
    fi

    # Reset
    IFS=" " read -r -a ips_store <<< ""
    echo -e "HOSTNAME: ${endpoint[$counter]}"
    echo -e "HOSTNAME: ${endpoint[$counter]}" >> results/$logname

    loopcounter=0
    while [ $loopcounter -lt 10 ]
    do
        # Filter and map hostname's ips
        mapfile -t value_store < <(dig +short "${endpoint[$counter]}" | grep -oE '\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b' | tr '\n' ' ')
        value_store_length=${#value_store[@]}
        for ((ipcounter = 0; ipcounter < value_store_length; ipcounter++))
        do
            lists=""
            if [[ ! " ${ips_store[*]} " =~ " ${value_store[$ipcounter]} " ]]; then
                length=${#ips_store[@]}
                for ((l = 0; l < length; l++))
                do
                    ips_store+=("${value_store[$ipcounter]}")
                    lists+="${ips_store[$l]}\n"
                done

                if [[ "$loopcounter" != 0 ]]; then
                echo -e "IP CHANGED to ${value_store[$ipcounter]}\nIP LISTS:\n$lists"
                echo -e "IP CHANGED to ${value_store[$ipcounter]}\nIP LISTS:\n$lists" >> results/$logname
                fi
            fi
        done

        for ((i = 0; i < ${#ips_store[@]}; i++))
        do
            ip="${ips_store[$i]}"
            status_code=$(curl -sI https://$ip --insecure -m 2 | grep -Po "[0-9]{2,3}+" | head -n 1)
            if [ -n "$status_code" ]; then
            echo "[$(date)] ${ips_store[$i]} timeout"
            echo "[$(date)] ${ips_store[$i]} timeout" >> results/$logname
            else
            echo "[$(date)] ${ips_store[$i]} $status_code"
            echo "[$(date)] ${ips_store[$i]} $status_code" >> results/$logname
            fi
        done
        ((loopcounter=loopcounter+1))
        sleep 0.5
    done
done