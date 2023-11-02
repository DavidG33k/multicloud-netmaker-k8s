# How to reproduce 
### Netmaker server installation
1. Get a cloud VM with Ubuntu 22.04 and a public IP, building a new EC2 instance with the following specs:
    -  A generic name (*NetMaker-server* in owr case);
    - Image: Ubuntu Server 22.04 LTS (HVM);
    - Architecture 64-bit (x86);
    - Type of instance: t3.micro (the default one);
    - key pair for secure connection: RSA chiper and .ppk type to use PuTTY (alternatively .pem to use OpenSSH);
    - Firewall: create new security group authorizing SSH, HTTPS, and HTTP traffic;
    - 20 GiB - gp2 (20GiB not required, just to be shure).
2. Set an elastic IP address (to keep the same IP address):
    - In the left navigation bar, select the *Network & Security -> Elastic IPs* menu item;
    - Click on *Assign Elastic IP address*;
    - Leave all setting by default, set a generic name and click on *Assign*;
    - Go to *Actions -> Associate Elastic IP address*, then select the Netmaker server instance and check the reassociation option.
3. Run the instance and connect Open ports 443, 80, 3479, 8089 and 51821-51830/udp on the VM firewall with the fallowing commands:
    - `sudo ufw allow 443`
    - `sudo ufw allow 80`
    - `sudo ufw allow 3479`
    - `sudo ufw allow 8089`
    - `sudo ufw allow 51821:51830/udp`
4. Set a wildcard subdomain in the DNS resolver, e.g. *.netmaker.example.com, which points to the VM's pubic IP. It is important to note that Netmaker manage SSL certificates through [Letsencrypt](https://letsencrypt.org/), so for free domain we must check that they are present in the [Public Suffix list](https://publicsuffix.org/list/), otherwise we can reach the rate limit of Letsencrypt.\
As DNS resolver I used [Dynu](https://www.dynu.com/) (maybe the only one in the list with wildcards allowed, with free 3rd level domains and without rate limits 🤯):
    - Cick on *Create Account* and proceed creating a new account (no credit card info required), then verify your email and logged in;
    - Open the [Control Plane](https://www.dynu.com/en-US/ControlPanel), click on *DDNS Services*, then press *Add*;
    - In the *Host* field put "netmaker" and choose a *Top Level* domain.
    - Turn back to *DDNS Services* and now click on our new domain to set the VM's public IP (IPv6 not required).
    - In the *Wildcard Settings* it is possible to check if they are automatically enabled.
5. Go back to PuTTY and run the setup script:
    - Run `sudo wget -qO /root/nm-quick.sh https://raw.githubusercontent.com/gravitl/netmaker/master/scripts/nm-quick.sh && sudo chmod +x /root/nm-quick.sh && sudo /root/nm-quick.sh`;
    - Select the Community Edition ([here](https://docs.netmaker.org/ee/index.html) the version differences. The Enterprise Edition has a free plan but with usage limits);
    - Select *Custom Domain* and put our DNS domain record (without wildcard, in my case *netmaker.ddnsfree.com*), then check the subdomains and confirm if they are correct;
    - Continue customizing the credentials or leaving the default ones.

    **NOTE**: If you reach the Caddy connection time out, wait 5 minutes and retry!
6. Open the dashboard via browser and sign up a new admin account.

### Network Creation
1. First of all we have to delete the network created by default. On the left panel go on *Network*, press on the default network named "netmaker", then in the *Host* tab remove our host. Now go on *Network setting* to delete th network;
2. From the left panel turn to *Networks*, then *All Network*;
3. Press *Add a Network*, then *Autofill* to generate a new IPv4 (mask 24 by default, put 19 or 16 instead to connect much then 256 hosts to the network), change the name if you want to customize it and then set the *Default Access Control* to *DENY* (we will able to manage later the access via ACL).
4. From the left panel go to *Enrollment Keys*, delete the key of the old default network and create a new one for our new network pressing on *Create Key*. Put a generic name, on *Type* select "Unlimited" and select our network. This new generated key is required for the NetClient installation on other nodes.

### Clients Installation and distributed cluster creation.
The goal of this part is the creation of a distributed cluster using machines of different regions, installation of the NetClient for all nodes and then establish a connection. The chosen regions are in EU: Frankfurt, Ireland and London (just cause they are the cheapest).\
It's important to create the cluter master node first and configure it to work with the VPN connection, than add the other node to the cluser!\
The following procedure is the same for each node with some differeneces for the master:
1. Choose a region (Frankfurt for example);
4. A pre-requisite is a VPC for each region:
    - In the search bar search for VPC and click on "VPC", then on *Create VPC*;
    - Select *VPC and more*, put "frankfurt-NetMaker-VPC" as tag name and "18.0.0.0/16" as CIDR IPv4 (or another different IP from the others existing VPCs), then click *Create VPC*;
    - Click on "Your VPC" then on your VPC ID. For each subnet change subnet settings to enable automatic assignment of public IPv4 address.
5. Let's create the EC2 with the following specs (same specs for all nodes):
    - OS: Ubuntu 22.04;
    - Istance type: m5a.large;
    - Key pair: depend on your connection mode;
    - Network settings: select your custom VPC and enable the auto public IP assignment. Add a new role to remove any firewall restrictions (just for test, during the production enable just the [Microk8s needed ports](https://microk8s.io/docs/services-and-ports)!);
    - Storage: 20GB (just to be shure).
6. Connect to the instance, than follow the simple procedure to install the NetClient and add the node to the network. Just open the NetMaker dashboard, click on our network, then on the *Hosts* tab click on *Add new Host*. Select the network name, the Linux OS, and copy and paste to proceed.
7. To setup Microk8s copy and paste:
    1. `sudo apt update && sudo apt install snapd`;
    2. `sudo systemctl enable --now snapd.socket`;
    3. `sudo hostnamectl set-hostname <NM-DNS-HOSTNAME>`;
    4. `sudo snap install microk8s --classic`;
    5. `sudo usermod -a -G microk8s $USER`;
    6. `sudo chown -f -R $USER ~/.kube`;
    7. `sudo su - && su - $USER`;

    On control plane only **BEFORE** add workers to the cluster: run `microk8s enable dns`, then add the following three lines in /var/snap/microk8s/current/args/kube-apiserver:
    ```
    --advertise-address=<CONTROLPLANE-VPN-PRIVATE-IP>
    --bind-address=0.0.0.0
    --secure-port=16443
    ```
    Apply changes with `sudo snap restart microk8s`.
8. To add nodes to control plane run `microk8s add-node` on control plane, then copy the suggested command with the VPN IP and add *--worker* before run it on the worker nodes. 
9. Test pods connectivity (also between different regions and clouds, if you want to integrate Azure/Google VMs):
    - First check the *Ready* status of all nodes with `microk8s kubectl get nodes -o wide` and check if the *internal IPs* are the same of the VPN network;
    - Let's test the pods connectivity deploying [this](https://raw.githubusercontent.com/gravitl/netmaker/master/k8s/misc/pingtest.yaml) .yaml file. Just edit to customize the number of replicas. To deploy run on master `microk8s kubectl apply -f pingtest.yaml`;
    - To open a remote shell to a pod run `microk8s kubectl exec -it <PINGTEST-POD-NAME> -- sh`. You can find pod name and pod IPs to ping with `microk8s kubectl get pods -o wide`.