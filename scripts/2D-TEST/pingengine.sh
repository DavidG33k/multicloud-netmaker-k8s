#!/bin/bash

S3_BUCKET_NAME=""  # put your S3 bucket name

HOSTNAME_OR_IP=""  # put the hostname or ip to ping 

num_of_tests=50  # number of repetitions

MACHINE_INFO=""  # put an identifier of your machine (just to not overwrite files)

output_file="${MACHINE_INFO}_ping_results.txt"

i=0
while [ "$i" -lt $num_of_tests ]; do
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    result=$(ping -c 50 -q -n -i 0.2 $HOSTNAME_OR_IP)
    
    echo "$timestamp - Test $i: $result" >> "$output_file"
    echo "" >> "$output_file"
    echo "" >> "$output_file"
    aws s3 cp "$output_file" "s3://$S3_BUCKET_NAME/$output_file"

    echo "Ping results updated! $timestamp"
    echo "Next in an hour..."

    sleep 3600  # Wait an hour before next test (put your desired waiting time instead)

    i=$(( i + 1 ))
done

echo ""
echo "TESTS COMPLETED!" 