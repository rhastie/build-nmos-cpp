# AMWA NMOS Containerised Registry, Browser Client/Controller and Node

## Implementation Overview

This repository contains all the files needed to create a Dockerised container implementation of the AMWA Networked Media Open Specifications. For more information about AMWA, NMOS and the Networked Media Incubator, please refer to http://amwa.tv/.

This work is principally based on the open-sourced implementation from Sony. Please see: http://github.com/sony/nmos-cpp

The resulting Docker Container is specifically optimised to operate on a Mellanox switch, but can also function independently on many other platforms. Please see overview presentation from the IP Showcase @ IBC 2019:

- [Video Presentation](https://youtu.be/MXbepL2lmK4)
- [Slides](http://www.ipshowcase.org/wp-content/uploads/2019/10/1500-Simplifying-JT-NM-TR-1001-1-Deployments-through-Microservices.pdf)

Specifically the implementation supports the following specifications:

- AMWA IS-04 NMOS Discovery and Registration Specification (supporting v1.0-v1.3)
- AMWA IS-05 NMOS Connection Management Specification (supporting v1.0-v1.1)
- AMWA IS-07 NMOS Event & Tally Specification (supporting v1.1)
- AMWA IS-09 NMOS System Specification (originally defined in JT-NM TR-1001-1:2018 Annex A) (supporting v1.0-Dev)
- AMWA BCP-002-01 NMOS Grouping Recommendations - Natural Grouping
- AMWA BCP-003-01 NMOS API Security Recommendations - Securing Communications

Additionally it supports the following additional components:

- Supports auto identification of the switch Boundary Clock PTP Domain which is published via the AMWA IS-09 System Resource when run on a Mellanox switch
- Supports an embedded NMOS Browser Client/Controller which support NMOS Control using AMWA IS-05
- Supports a DNS-SD Bridge to HTML implementation that supports both mDNS and DNS-SD

The nmos-cpp container includes implementations of the NMOS Node, Registration and Query APIs, and the NMOS Connection API. It also included a NMOS Browser Client/Controller in JavaScript and a DNS-SD API which aren't part of the specifications.

## Tested Platforms and CPU Architectures

The Dockfile in this repository is designed so that if needed it can be run under the Docker Experimental BuildX CLI feature set. The container is published for the follow CPU Architectures:

- Intel and AMD x86_86 64-bit architectures
- ARMv8 AArch64 (64-bit ARM architecture)
- ARMv7 AArch32 (32-bit ARM architecture)

The container has been tested on the following platforms for compatibility:

- Mellanox SN2000, SN3000 and SN4000 Series switches
- Mellanox Bluefield family of SmartNICs (operating natively on the SmartNIC ARM cores)
- NVIDIA Jetson AGX Xavier Developer Kit (even though not tested the container should function on all NVIDIA AGX platforms)
- Raspberry Pi RPi 3 Model B and RPi 4 Model B (both Raspbian's standard 32-bit and the new experimental 64-bit kernels have been tested)
- Standard Intel and AMD Servers running the container under Ubuntu Linux - Both bare-metal and virtualised environments have been tested. 

## How to install and run the container

### On a Mellanox Switch running Onyx NOS

Prerequisites:

- Run Onyx version 3.8.2000+ as a minimum
- Set an accurate date and time on the switch - Use PTP, NTP or set manually using the "clock set" command
- Create and have "interface vlans" for all VLANs that you want the container to be exposed on

Execute the following switch commands to download and run the container on the switch:

- Login as administrator to the switch CLI
- "docker" - Enables the Docker subsystem on the switch (Make sure you exit the docker menu tree using "exit")
- "docker no shutdown" - Activates Docker on the switch
- "docker pull rhastie/nmos-cpp:latest" - Pulls the latest version of the Docker container from Docker Hub
- "docker start rhastie/nmos-cpp latest nmos now privileged network" - Start Docker container immediately
- "docker no start nmos" - Stops the Docker container

Additional/optional steps:

On a Mellanox switch the DNS configuration used by the container is inherited from the switch configuration
- If you want to configure a DNS server for use by the container you can use the "ip name-server" switch command to specify a DNS server. By default, the container will use any DNS servers provided by DHCP
- If you want to configure a DNS search domain for the container you can use the "ip domain-list" switch command to specify DNS search domains. By default, the container will use any DNS search domains provided by DHCP. In the absence of any being configured it will default to ".local" ie. mDNS
- If you want to understand the current DNS configuration use the switch command "show hosts"

### On a Mellanox Bluefield Smart NIC

Prerequisites:

- It's generally recommended to use the Ubuntu 18.04+ based BFB (Bluefield bootstream) image as this contains all necessary drivers and OS as a single bundle. See [download page](https://www.mellanox.com/products/software/bluefield)
- Have an accurate date and time
- Make sure external connectivity and name resolution are available from the SmartNIC Ubuntu OS - There are several ways that this can be done. Please review the Bluefield documentation
- Docker is generally provided under the Mellanox BFB image, but if not available, install a full Docker CE environment using [instructions](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- Set [docker permission](https://superuser.com/questions/835696/how-solve-permission-problems-for-docker-in-ubuntu#853682) for your host user

Execute the follow Linux commands to download and run the container on the host:

```sh
docker pull rhastie/nmos-cpp:latest
docker run -it --net=host --privileged --rm rhastie/nmos-cpp:latest
```

### On a NVIDIA Jetson AGX Developer Kit

Prerequisites:

- It's generally recommended to run the very latest JetPack from NVIDIA (JetPack 4.3 at the time of testing)
- Have an accurate date and time
- Docker is generally provided under the NVIDIA JetPack image, but if not available, install a full Docker CE environment using [instructions](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- Set [docker permission](https://superuser.com/questions/835696/how-solve-permission-problems-for-docker-in-ubuntu#853682) for your host user

Execute the follow Linux commands to download and run the container on the host:

```sh
docker pull rhastie/nmos-cpp:latest
docker run -it --net=host --privileged --rm rhastie/nmos-cpp:latest
```

### Raspberry Pi RPi 3 Model B and RPi 4 Model B

Prerequisites:

- It's generally recommended to run latest version of Raspbian (Buster at the time of testing)
- Have an accurate date and time
- If using Raspbian Buster you can installed Docker using "sudo apt-get install docker.io". If using older versions of Raspbian install a full Docker CE environment using [instructions](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- Set [docker permission](https://superuser.com/questions/835696/how-solve-permission-problems-for-docker-in-ubuntu#853682) for your host user

Execute the follow Linux commands to download and run the container on the host:

```sh
docker pull rhastie/nmos-cpp:latest
docker run -it --net=host --privileged --rm rhastie/nmos-cpp:latest
```

### On a standard Linux host

Prerequisites:

- It's generally recommended to run using Ubuntu 18.04+
- Have an accurate date and time
- Install a full Docker CE environment using [instructions](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- Set [docker permission](https://superuser.com/questions/835696/how-solve-permission-problems-for-docker-in-ubuntu#853682) for your host user

Execute the follow Linux commands to download and run the container on the host:

```sh
docker pull rhastie/nmos-cpp:latest
docker run -it --net=host --privileged --rm rhastie/nmos-cpp:latest
```

## Accessing the Web GUI Interface

The container publishes on all available IP addresses using port 8010

- Browse to http://[Switch or Host IP Address>]:8010 to get to the Web GUI interface.
- The NMOS Registry is published on the "x-nmos" URL
- The NMOS Browser Client is published on the "admin" URL

## How to build the container

- Make sure you have a fully function Docker CE environment. It is recommended you follow [the instructions for Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- Clone this repository to your host
- Run:

```sh
make build
```
