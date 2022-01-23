# CHECK THE CARBURATOR
echo -e "Rolling back and remove the ip and hostname inside the SCHEDULER FLAG...\n"
echo -e "\n[TASK] Checking the /etc/hosts path..."
hostspath=/etc/hosts # WE CAN SIMPLY CHANGE THIS FOR DEBUGGING
if [ ! -f "$hostspath" ]; then
    echo "✗ File ${hostspath} not found on your machine!"
    echo "exitting..."
    exit 1
else
    echo "✓ File ${hostspath} is found, continue to the next task..."
fi

echo -e "\n[TASK] Checking the ${hostspath}, whether the file has a SCHEDULER FLAG to assign the ip and hostname..."
SCHEDULERFLAG=$(cat ${hostspath} | grep -Pzo "# SCHEDULER FLAG #(.|\n)*\# END SCHEDULER FLAG #" | tr '\n' ' ')

echo "found" "$SCHEDULERFLAG"

# SELECT ONLY THE PATTERN
pattern="[#]+[\ END]+[SCHEDULER]+[\ ]+[FLAG]+[\ ]+[#]+"
if [[ "$SCHEDULERFLAG" =~ $pattern ]]; then
    echo "✓ File ${hostspath} has the requirement flag, continue to the next task..."
else
    echo "✗ File ${hostspath} on your machine doesn't has the requirement flag to assign IP and Hostname with this script!"
    echo "The ${hostspath} file should have had # SCHEDULER FLAG # as the prefix and # END SCHEDULER FLAG # as the postfix"
    echo "exitting..."
    exit 1
fi

# ASSIGN THE VARIABLE TO /etc/hosts BY SED COMMAND, USE -i FLAG TO REPLACE FILE IMMEDIATELY
echo -e "\n[TASK] Revert to null ip and hostname in /etc/hosts..."
# SELECT ALL FLAG AND ALSO THE CONTENT INSIDE IT (IP HOSTNAME WITH HYPENS, DOT, NUMBERS, SEPARATED BY SPACE AND NEW LINE)
pattern2="[#]+[\ ]+[SCHEDULER]+[\ ]+[FLAG]+[\ ]+[#]+[0-9\.\na-zA-Z\.\r\ -]*[#]+[\ END]+[SCHEDULER]+[\ ]+[FLAG]+[\ ]+[#]+"
sed -i -Ez "s/$pattern2/# SCHEDULER FLAG #\n# END SCHEDULER FLAG #/g" ${hostspath}
echo -e "\n[COMPLETED] Revert to null ip and hostname in /etc/hosts is completed."