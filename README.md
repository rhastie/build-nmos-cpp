# AMWA NMOS Containerised Node and Registry
## Implementation Overview
This repository contains all the Docker files needed for an 
implementation of the AMWA Networked Media Open Specifications. The 
resulting Docker Container is specifically optimised to operate on a 
Mellanox switch, but can also function independently on a standard host. 
Please see overview presentation from the IP Showcase at IBC 2019: Video 
- https://youtu.be/MXbepL2lmK4 and Slides - 
http://www.ipshowcase.org/wp-content/uploads/2019/10/1500-Simplifying-JT-NM-TR-1001-1-Deployments-through-Microservices.pdf 
Specifically the implementation supports the following specifications:
 - AMWA IS-04 NMOS Discovery and Registration Specification (supporting 
v1.0-v1.3)
 - AMWA IS-05 NMOS Connection Management Specification (supporting 
v1.0-v1.1)
 - AMWA IS-07 NMOS Event & Tally Specification (supporting v1.1)
 - AMWA IS-09 NMOS System Specification (originally defined in JT-NM 
TR-1001-1:2018 Annex A) (supporting v1.0-Dev)
 - AMWA BCP-002-01 NMOS Grouping Recommendations - Natural Grouping
 - AMWA BCP-003-01 NMOS API Security Recommendations - Securing 
Communications Additionally it supports the following additional 
components:
 - Supports auto identification of the Boundary Clock PTP Domain and 
published via AMWA IS-09 System Resource when run on a Mellanox switch
 - Supports an embedded NMOS Browser Client
 - Supports a DNS-SD Bridge to HTML implementation For more information 
about AMWA, NMOS and the Networked Media Incubator, please refer to 
http://amwa.tv/. The nmos-cpp container includes implementations of the 
NMOS Node, Registration and Query APIs, and the NMOS Connection API. It 
also included a NMOS Client in JavaScript and DNS-SD API which aren't 
part of the specifications.
## How to install and run the container
### On a Mellanox Switch running Onyx NOS
Prerequisites:
 - Run Onyx version 3.8.2000+ as a minimum
 - Set accurate date and time on the switch - Use PTP, NTP or set 
manually using the "clock set" command
 - Create and have "interface vlans" for all VLANs that you want the 
container to be exposed on Execute the following switch commands to 
download and run the container on the switch:
 - Login as administrator to the switch CLI
 - "docker" - Enables the Docker subsystem on the switch (Make sure you 
exit the docker menu tree using "exit")
 - "docker no shutdown" - Activates Docker on the switch
 - "docker pull rhastie/nmos-cpp:latest" - Pull the latest version of 
the Docker container from Docker Hub
 - "docker start rhastie/nmos-cpp latest nmos now privileged network" - 
Start Docker container immediately
 - "docker no start nmos" - Stops the Docker container
### On a standard Linux host
Prerequisites:
 - Recommended to run using Ubuntu 18.04+
 - Have an accurate date and time
 - Install a full Docker CE environment using these instructions: 
https://docs.docker.com/v17.09/engine/installation/linux/docker-ce/ubuntu/ 
Execute the follow linux commands to download and run the container on 
the host:
 - sudo docker pull rhastie/nmos-cpp:latest
 - sudo docker run -it --net=host --privileged --rm 
rhastie/nmos-cpp:latest
### Access Web interface
 - Browser to http://[Switch or Host IP Address>]:8010 to get to the 
interface.
 - The NMOS REgistry is published on the "x-nmos" URL
 - The NMOS Browser Client is published on the "admin" URL
# How to build the container
Make sure you have a fully function Docker CE environment. It is 
recommended you follow these instructions for Ubuntu: 
https://docs.docker.com/v17.09/engine/installation/linux/docker-ce/ubuntu/ 
Clone the repository to your host
Run "sudo make build"

