#!/bin/bash

S3_BUCKET_NAME=""  # put your S3 bucket name

pod_ip=""  # put your pod IP
server_port="5001"  # put iperf port (5001 TCP is the default one)

num_of_tests=12  # number of repetitions

MACHINE_INFO=""  # put an identifier of your machine (just to not overwrite files)

output_file_iperf_pod="${MACHINE_INFO}_iperf_pod_results.txt"
output_file_ping_pod="${MACHINE_INFO}_ping_pod_results.txt"

i=0
while [ "$i" -lt $num_of_tests ]; do
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    iperf_pod_result=$(iperf -c $pod_ip -p $server_port -t 10 -f M | tail -n 1)
    sleep 1
    ping_pod_result=$(ping -c 50 -q -n -i 0.2 $pod_ip)

    # Write results in local files
    echo "$timestamp - Test $i to $pod_ip :   $iperf_pod_result" >> "$output_file_iperf_pod"
    echo "" >> "$output_file_iperf_pod"
    echo "" >> "$output_file_iperf_pod"
    echo "$timestamp - Test $i to $pod_ip :   $ping_pod_result" >> "$output_file_ping_pod"
    echo "" >> "$output_file_ping_pod"
    echo "" >> "$output_file_ping_pod"

    # Copy local files to S3 bucket
    aws s3 cp "$output_file_iperf_pod" "s3://$S3_BUCKET_NAME/SYNC-TESTS/$output_file_iperf_pod"
    aws s3 cp "$output_file_ping_pod" "s3://$S3_BUCKET_NAME/SYNC-TESTS/$output_file_ping_pod"

    echo "Results updated! $timestamp"
    echo "Next in 5 minutes..."

    sleep 300  # Wait 5 minutes before next test (put your desired waiting time instead)

    i=$(( i + 1 ))
done

echo ""
echo "TESTS COMPLETED!" 