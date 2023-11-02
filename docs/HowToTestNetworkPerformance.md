# How to test network performance
Let's suppose that we want to save all test results in an S3 bucket. A pre-requisite is the creation of a bucket via AWS S3 dashboard and the attachment of a role for each cluster node to allow the access to the bucket.\
Moreover, we want the test node-to-node performance (answer time, traceroute and throughput) via public and private ip, and also pod-to-pod performance.\
To save the results in the S3 bucket, we must install the *aws cli* to nodes and pods. About the pods:\
The previous "pingtest.yaml" used to deploy our pods do not allow the installation of other packages cause it use a very lite linux image (busybox image) without any package manager. An easy fix is to edit the .yaml file and change the image with a debian release, which will allow us to use the apt package manager:
1. Download the new [pingtest.yaml](https://pastebin.com/raw/0Kw4EUa1);
2. Re-apply the deploy with: `kubectl apply -f pingtest.yaml`.

### Nodes/Pods initialization and AWS CLI setup
For each node:
1. Run `sudo apt update && apt install -y lft iperf awscli`;
2. Test with `aws s3 ls <S3-BUCKET-NAME>`.
For each pod:
1. Enter to the pod from master node running `kubectl exec --stdin --tty <POD-NAME> -- bash`;
2. Run `apt update && apt install -y iproute2 procps nano iperf awscli iputils-ping lft` (the first three are not mandatory, but necessary if you want to edit the script, see if they are running as process and check the interface cards);
3. Test with `aws s3 ls <S3-BUCKET-NAME>`.

### Performance checks
To obtain more accurate results, the tests were scheduled as follows:
- Answer time via ICMP with *ping*, traceroute via TCP with *lft* and throughput via TCP with *iperf* (you need to install also iperf and lft for each node and pods as suggested befores!);
- Tests repeted for node-to-node connectivity via public and private VPN IPs, and also for pod-to-pod connectivity via Calico IPs;
- 2 days tests: 50 ping, lft and iperf runs (1 per hour), from each region and cloud (AWS, Azure), to every other region.
- 1 hour tests: 12 ping, lft and iperf runs (1 every 5 minutes), just for region to another one.

To automate them the following scripts were written:
- [pingengine.sh](https://pastebin.com/raw/ATcbS0Mq)
- [iperfengine.sh](https://pastebin.com/raw/7HKBX8dc)
- [lftfengine.sh](https://pastebin.com/raw/VfBLpH65)
- [synctest.sh](https://pastebin.com/raw/fDceBw3m) used for the 1h test
- [synctest-podedition.sh](https://pastebin.com/raw/bhdbihJy) used also for the 1h test but for pods

Copy the script via wget (or copy and paste it) and edit to customize info.\
**Just remember**:
- Start the iperf server on the other side before run the script with `iperf -s -D`;
- Open the port to perform iperf on the iperf server (read script to know which port to open);
- Allow ICMP and TCP traffic.

At this point you may need to change the MTU (*Maximum Transmission Unit*) values to find the best equilibrium between stability and performance (lower MTU = much stability, higher MTU = much performance).\
By default, for example in my case, AWS sets for his network interfaces an MTU of 9001 and Calico (the component that manage the communication between pods) calculete the MTU as 9001-50, **BUT** we have another layer (our VPN) and we mapped microk8s on him. By default NetMaker set a value of 1420 for each hosts to ensure stability and **in my case** this led to drops in the throughput during the pod tests, maybe caused because the high MTU of the pods (9001-50) and the low MTU of the NetMaker interfaces (1420) in which the pods are mapped to. After testing I found a good equilibrium with an MTU of 6000 for the NetMaker interfaces and so 5950 for the pods.

To change the MTU value for pods:
1. On master terminal run `kubectl patch configmap/calico-config -n kube-system --type merge -p '{"data":{"veth_mtu": "5950"}}'`;
2. than restart calico deamon with `kubectl rollout restart daemonset calico-node -n kube-system`;
3. than restart microk8s service with `microk8s stop && microk8s start`.

To change the MTU value for NetMaker interfaces:
1. Open the dashboard, than on the left panel *Hosts*.
2. For each hosts in the network click on *Edit Host* and put your value on the MTU field.