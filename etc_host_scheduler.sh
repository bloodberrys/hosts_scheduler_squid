#!/bin/bash

echo "============================================================================"
echo "================== THIS SCRIPT PERFORMED BY THE CRON JOB ==================="
echo "============================================================================"
echo "TO LOOKUP OUR PARTNER DNS A RECORD THAT MAPS ON THE SPECIFIC IP RESPECTIVELY"
echo "TO SUPPORT THE SQUID DNS CACHE PROBLEM, WE CREATE THIS SCRIPT AS IS"
echo "SOME MODIFICATION ON THIS SCRIPT WILL BE GRANTED IF YOU HAVE A PERMISSION "
echo "FROM THE MAINTAINER, REST ASSURED THIS WILL FIX THE SQUID 503 ANNOYING FLAWS"
echo "============================================================================"

# CHECK THE TIRES BEFORE OUR ADVENTURES
echo -e "\n[PRE-TASK] Obtaining and processing the partner domains from /etc/squid/squid.conf..."
squidconfpath=squid.conf # WE CAN SIMPLY CHANGE THIS FOR DEBUGGING
if [ ! -f "$squidconfpath" ]; then
    echo "✗ File ${squidconfpath} not found on your machine!"
    echo "exitting..."
    exit 1
else
    echo "✓ File ${squidconfpath} is found, continue to the next task..."
fi

# GATHER PARTNER HOSTNAME IN /etc/squid/squid.conf AS SOURCE OF TRUTH
# THIS ACTION WILL ENSURE THAT WE HAVE THE CONSISTENT PARTNER LISTS
# THE OUTPUT WILL BE SEPARATED BY SPACE
PARTNER_ENDPOINTS=$(cat ${squidconfpath} | grep -Po 'acl paypartner-dstdomain dstdomain [^\s]*' | awk '{sub(/acl paypartner-dstdomain dstdomain /,"")}1' | tr '\n' ' ')

# ASSIGN THE PARTNERS TO "endpoint" ARRAY
IFS=" " read -r -a endpoint <<< "$PARTNER_ENDPOINTS"

# GET THE ARRAY ELEMENTS LENGTH
endpointlength=${#endpoint[@]}

# PREPARE A GLASS OF COFFEE
hostname_success_counter=0
hostname_failed_counter=0
total_resolved_ips=0
total_cname=0
known_dns_counter=0

# OH YEAH START EVERYTHING?
echo -e "\n[WARM-UP] The script is about to start...\n"

# JUST IN CASE WE NEED THE EXECUTION TIME, OR TIMESTAMP AS ALWAYS
date_start=$(date)
read -r up rest </proc/uptime; t1="${up%.*}${up#*.}"

# START TO DIG DIVE INTO THE OCEAN, RED OCEAN OR BLUE OCEAN?
echo -e "\n[MAIN-TASK] Resolving the hostnames..."
for (( i = 0; i < endpointlength; i++))
do
    # FIND WITH DIG WHICH HOSTNAME IS ACTUALLY DOESN'T HAVE AN A RECORD
    cmd1="dig ${endpoint[$i]} A"
    cmd2="grep NOERROR"
    go=$(eval "$cmd1" | eval "$cmd2")
    if [[ -n "$go" ]]; then
        hostname_success_counter=$((hostname_success_counter+1));
    else
        echo "[WARNING] Hostname doesn't have an A record (SOA/NXDOMAIN): ${endpoint[$i]}";
        hostname_failed_counter=$((hostname_failed_counter+1)); failed_lists+="${hostname_failed_counter}. ${endpoint[$i]}\n";
    fi

    # RESOLVE THE HOSTNAME'S IPS
    mapfile -t ips < <(dig +short "${endpoint[$i]}")

    for (( j = 0; j < ${#ips[@]}; j++))
    do
        known_dns_counter=$((known_dns_counter+1))

        # FILTER THE RESULT, SO THAT WE CAN ONLY OBTAIN THE IP ADDRESS
        # AND PREVENTING ANOHER ALIAS
        echo "${ips[$j]}"
        ip=$(echo "${ips[$j]}" | grep -oE '\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b')

        # ASSIGN TO THE LISTS
        if [[ -n "$ip" ]]; then
            # (DEBUGGING PURPOSE ONLY)
            # UNCOMMENT THE LINE BELOW TO PRINT THE IPS AND PARTNER HOSTNAMES#
            # echo "${ip}" "${endpoint[$i]}"

            # GENERATE A SUCCESS HOSTNAME WITH \n
            lists+="${ip} ${endpoint[$i]}\n"
            total_resolved_ips=$((total_resolved_ips+1))
        else
            # HOSTNAME THAT HAS CNAME RECORD
            total_cname=$((total_cname+1))
        fi
    done
done
date_end=$(date)
read -r up rest </proc/uptime; t2="${up%.*}${up#*.}"
duration=$(( 10*(t2-t1) ))

# JUST IN CASE NEED DEBUG, UNCOMMENT THE PART BELOW
# echo $lists

# CHECK THE CARBURATOR
echo -e "\n[TASK] Checking the /etc/hosts path..."
hostspath=hosts # WE CAN SIMPLY CHANGE THIS FOR DEBUGGING
if [ ! -f "$hostspath" ]; then
    echo "✗ File ${hostspath} not found on your machine!"
    echo "exitting..."
    exit 1
else
    echo "✓ File ${hostspath} is found, continue to the next task..."
fi

echo -e "\n[TASK] Checking the ${hostspath}, whether the file has a SCHEDULER FLAG to assign the ip and hostname..."
SCHEDULERFLAG=$(cat ${hostspath} | grep -Pzo "# SCHEDULER FLAG #(.|\n)*\# END SCHEDULER FLAG #" | tr '\n' ' ')


# SELECT ONLY THE PATTERN
pattern="[#]+[\ END]+[SCHEDULER]+[\ ]+[FLAG]+[\ ]+[#]+"
if [[ "$SCHEDULERFLAG" =~ $pattern ]]; then
    echo "Found" "$SCHEDULERFLAG"
    echo "✓ File ${hostspath} has the requirement flag, continue to the next task..."
else
    echo "✗ File ${hostspath} on your machine doesn't has the requirement flag to assign IP and Hostname with this script!"
    echo "The ${hostspath} file should have had # SCHEDULER FLAG # as the prefix and # END SCHEDULER FLAG # as the postfix"
    echo "exitting..."
    exit 1
fi

# ASSIGN THE VARIABLE TO /etc/hosts BY SED COMMAND, USE -i FLAG TO REPLACE FILE IMMEDIATELY
echo -e "\n[TASK] Replacing ip and hostname in /etc/hosts..."
# SELECT ALL FLAG AND ALSO THE CONTENT INSIDE IT (IP HOSTNAME WITH HYPENS, DOT, NUMBERS, SEPARATED BY SPACE AND NEW LINE)
pattern2="[#]+[\ ]+[SCHEDULER]+[\ ]+[FLAG]+[\ ]+[#]+[0-9\.\na-zA-Z\.\r\ -]*[#]+[\ END]+[SCHEDULER]+[\ ]+[FLAG]+[\ ]+[#]+"
sed -i -Ez "s/$pattern2/# SCHEDULER FLAG #\n${lists}# END SCHEDULER FLAG #/g" ${hostspath} && { is_sed_success=1; echo "Replace completed"; } || { is_sed_success=0; echo -e "Replace failed...\nexitting"; exit 1; }

# LOG THE /etc/hosts
echo -e "\n\n[POST-CHECKING] Print the /etc/hosts RESULT...\n"
cat ${hostspath}
echo -e "\n\n"
if [ $is_sed_success -eq 1 ]; then
    echo -e "\n[MISSION ACCOMPLISHED] IP and hostname in /etc/hosts is completely replaced."
fi

# LOGGING PURPOSE
echo ".========================================================."
echo "|===============DNS RESOLVER SCHEDULER RECAP=============|"
echo "'========================================================'"
echo "⧖ Script started at: ${date_start}"
echo "⧗ Script ended at: ${date_end}"
echo "◷ Execution time: ${duration} ms"
echo ".========================================================."
echo "|=========================STATS==========================|"
echo "'========================================================'"
echo "OY's total partner hostname: ${endpointlength}/${endpointlength}"
echo -e "Total DNS RECORD found based on available hostname: $((known_dns_counter+hostname_failed_counter))\n"
echo "✓ Hostnames resolved Successfully (NOERROR): ${hostname_success_counter}/${endpointlength}"
echo "✓ The amount of IPs (A Record) whose hostname can be resolved: ${total_resolved_ips}"
echo "⚠ Hostnames which has CNAME record: ${total_cname}"
echo "✗ Amount of Failed hostname to be resolved (SOA/NXDOMAIN): ${hostname_failed_counter}/${endpointlength}"
echo -e "${failed_lists}"
echo ".========================================================."
echo "|======================END OF RECAP======================|"
echo "'========================================================'"
