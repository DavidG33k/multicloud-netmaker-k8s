#!/bin/bash

S3_BUCKET_NAME=""  # put your S3 bucket name

server_ip=""  # put your iperf listening server
server_port="5001"  # put iperf port (5001 TCP is the default one)

num_of_tests=50  # number of repetitions

MACHINE_INFO=""  # put an identifier of your machine (just to not overwrite files)

output_file="${MACHINE_INFO}_iperf_results.txt"

i=0
while [ "$i" -lt $num_of_tests ]; do
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    result=$(iperf -c $server_ip -p $server_port -t 10 -f M | tail -n 1)

    echo "$timestamp - Test $i to $server_ip :   $result" >> "$output_file"
    echo "" >> "$output_file"
    echo "" >> "$output_file"
    aws s3 cp "$output_file" "s3://$S3_BUCKET_NAME/$output_file"

    echo "Iperf results updated! $timestamp"
    echo "Next in an hour..."

    sleep 3600  # Wait an hour before next test (put your desired waiting time instead)

    i=$(( i + 1 ))
done

echo ""
echo "TESTS COMPLETED!" 