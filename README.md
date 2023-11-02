# multicloud-netmaker-k8s

## Description
Multicloud networking technique that uses Mesh VPNs (Peer2Peer connectivities) to improve network performances and avoid the issues of the typical Hub&Spoke VPNs, like the tunnel congestion.

## Test and Deploy
Following the main phases to recreate the network infrastructure. The first one is a StepByStep guide to create the a VPN server and a network sample, the second one to test the network and improve performances (if needed). 

- [ ] [How to reproduce](./docs/HowToReproduce.md)
- [ ] [How to test network performances](./docs/HowToTestNetworkPerformance.md)

## Project status
This first phase is completed, but it is just the first of a big idea. The next will be the implementation a cross-cloud data storage abstraction and the development of and SQL routing engine that, given a query, can understand which SQL engine and which cloud the query should be routed to minimize the amount of data transferred among clouds.

## Authors and acknowledgment
Davide Gena, CyberSec student of the University of Calabria.\
Special thanks to my tutors and supervisors Nicolò Bidotti and David Greco.
