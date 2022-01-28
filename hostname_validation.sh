#!/bin/bash

echo -e "Script to test the hostname ip reliability."

mkdir -p results
mkdir -p ip_target
IFS=" " read -r -a ips_store <<< ""

endpoint="api-mt.thunes.com api.bni-ecollection.com api.bni.co.id dev.bni-ecollection.com apidev.bni.co.id api.danamon.co.id aping-ideal.dbs.com aping.dbs.id"
IFS=" " read -r -a endpoint <<< "$endpoint"
endpointlength=${#endpoint[@]}
for ((counter = 0; counter < endpointlength; counter++))
do
    # Log rotate for each endpoint
    logname="result.log"
    if [ -f "results/$logname" ]; then
        namerotator=$(ls results/ | grep -Po "${logname}[\.0-9]*" | tail -n 1 | awk "{sub(/${logname}[\.]*/,\"\")}1")
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
    timeoutcounter=0
    while [ $loopcounter -lt 1000 ]
    do
        # Filter and map hostname's ips
        mapfile -t value_store < <(dig +short "${endpoint[$counter]}" | grep -oE '\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b')
        value_store_length=${#value_store[@]}
        if [[ "$value_store_length" == 1 ]]; then
            lists=""
            if [[ ! " ${ips_store[*]} " =~ " ${value_store[0]} " ]]; then
                ips_store+=("${value_store[0]}")
                length=${#ips_store[@]}
                for ((l = 0; l < length; l++))
                do
                    lists+="${ips_store[$l]}\n"
                done
                if [[ "$loopcounter" != 0 ]]; then
                echo -e "FOUND NEW IP ${value_store[0]}\nIP LISTS:\n$lists"
                echo -e "FOUND NEW IP ${value_store[0]}\nIP LISTS:\n$lists" >> results/$logname
                fi
            fi

            # Sequence/single curl
            for ((i = 0; i < ${#ips_store[@]}; i++))
            do
                ip="${ips_store[$i]}"
                status_code=$(curl -sI https://$ip --insecure -m 2 | grep -Po "[0-9]{2,3}+" | head -n 1)
                if [ -n "$status_code" ]; then
                    echo "[$(date)] ${ips_store[$i]} $status_code"
                    echo "[$(date)] ${ips_store[$i]} $status_code" >> results/$logname
                if [[ "$status_code" =~ [5][0][0-9] ]]; then
                    timeoutcounter=$((timeoutcounter+1))
                fi
                else
                    echo "[$(date)] ${ips_store[$i]} timeout"
                    echo "[$(date)] ${ips_store[$i]} timeout" >> results/$logname
                    timeoutcounter=$((timeoutcounter+1))
                fi
            done
        else
            for ((ipcounter = 0; ipcounter < value_store_length; ipcounter++))
            do
                lists=""
                if [[ ! " ${ips_store[*]} " =~ " ${value_store[$ipcounter]} " ]]; then
                    length=${#ips_store[@]}

                    # Store value
                    ips_store+=("${value_store[$ipcounter]}")
                    lists+="${ips_store[$l]}\n"
                    if [[ "$loopcounter" != 0 ]]; then
                        echo -e "FOUND NEW IP ${value_store[$ipcounter]}\nIP LISTS:\n$lists"
                        echo -e "FOUND NEW IP ${value_store[$ipcounter]}\nIP LISTS:\n$lists" >> results/$logname
                    fi
                fi
            done

            # Save target ip to the file
            printf "%s\n" "${ips_store[@]}" > ip_target/ip_target_"${endpoint[$counter]}".txt
            # Parallel curl
            xargs -P 1 -n 1 -I@ bash -c "curl -sI https://@ --insecure -m 2 | grep -Po \"[0-9]{2,3}+\" | head -n 1 && echo \"[$(date)] @ \" >> results/$logname" < ip_target/ip_target_"${endpoint[$counter]}".txt >> results/$logname
        fi
        ((loopcounter=loopcounter+1))
        if [[ "$timeoutcounter" -gt 10 ]]; then
            break;
        fi
        sleep 0.5
    done
done