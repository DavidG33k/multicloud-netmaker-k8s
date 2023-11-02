#!/bin/bash

S3_BUCKET_NAME=""  # put your S3 bucket name

server_pub_ip=""  # put your iperf listening server
server_pvt_ip=""  # put your iperf listening server
server_port="5001"  # put iperf port (5001 TCP is the default one)

num_of_tests=12  # number of repetitions

MACHINE_INFO=""  # put an identifier of your machine (just to not overwrite files)

output_file_iperf_pub="${MACHINE_INFO}_iperf_pub_results.txt"
output_file_iperf_pvt="${MACHINE_INFO}_iperf_pvt_results.txt"
output_file_ping_pub="${MACHINE_INFO}_ping_pub_results.txt"
output_file_ping_pvt="${MACHINE_INFO}_ping_pvt_results.txt"

i=0
while [ "$i" -lt $num_of_tests ]; do
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    iperf_pub_result=$(iperf -c $server_pub_ip -p $server_port -t 10 -f M | tail -n 1)
    sleep 1
    iperf_pvt_result=$(iperf -c $server_pvt_ip -p $server_port -t 10 -f M | tail -n 1)
    sleep 1
    ping_pub_result=$(ping -c 50 -q -n -i 0.2 $server_pub_ip)
    sleep 1
    ping_pvt_result=$(ping -c 50 -q -n -i 0.2 $server_pvt_ip)

    # Write results in local files
    echo "$timestamp - Test $i to $server_pub_ip :   $iperf_pub_result" >> "$output_file_iperf_pub"
    echo "" >> "$output_file_iperf_pub"
    echo "" >> "$output_file_iperf_pub"
    echo "$timestamp - Test $i to $server_pvt_ip :   $iperf_pvt_result" >> "$output_file_iperf_pvt"
    echo "" >> "$output_file_iperf_pvt"
    echo "" >> "$output_file_iperf_pvt"
    echo "$timestamp - Test $i to $server_pub_ip :   $ping_pub_result" >> "$output_file_ping_pub"
    echo "" >> "$output_file_ping_pub"
    echo "" >> "$output_file_ping_pub"
    echo "$timestamp - Test $i to $server_pvt_ip :   $ping_pvt_result" >> "$output_file_ping_pvt"
    echo "" >> "$output_file_ping_pvt"
    echo "" >> "$output_file_ping_pvt"

    # Copy local files to S3 bucket
    aws s3 cp "$output_file_iperf_pub" "s3://$S3_BUCKET_NAME/SYNC-TESTS/$output_file_iperf_pub"
    aws s3 cp "$output_file_iperf_pvt" "s3://$S3_BUCKET_NAME/SYNC-TESTS/$output_file_iperf_pvt"
    aws s3 cp "$output_file_ping_pub" "s3://$S3_BUCKET_NAME/SYNC-TESTS/$output_file_ping_pub"
    aws s3 cp "$output_file_ping_pvt" "s3://$S3_BUCKET_NAME/SYNC-TESTS/$output_file_ping_pvt"

    echo "Results updated! $timestamp"
    echo "Next in 5 minutes..."

    sleep 300  # Wait 5 minutes before next test (put your desired waiting time instead)

    i=$(( i + 1 ))
done

echo ""
echo "TESTS COMPLETED!" 