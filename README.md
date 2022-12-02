# AMWA NMOS Containerised Registry, Browser Client/Controller and Node

**Build status:** [![ci-build-test-publish](https://github.com/rhastie/build-nmos-cpp/workflows/ci-build-test-publish/badge.svg?branch=master)](https://github.com/rhastie/build-nmos-cpp/actions?query=workflow%3Aci-build-test-publish)

## Implementation Overview

This repository contains all the files needed to create a Dockerised container implementation of the AMWA Networked Media Open Specifications. For more information about AMWA, NMOS and the Networked Media Incubator, please refer to http://amwa.tv/.

This work is principally based on the open-sourced implementation from Sony. Please see: http://github.com/sony/nmos-cpp

The resulting Docker Container is specifically optimised to operate on a Mellanox switch, but can also function independently on many other platforms. Please see overview presentation from the IP Showcase @ IBC 2019:

- [Video Presentation](https://youtu.be/MXbepL2lmK4)
- [Slides](http://www.ipshowcase.org/wp-content/uploads/2019/10/1500-Simplifying-JT-NM-TR-1001-1-Deployments-through-Microservices.pdf)

Specifically the implementation supports the following specifications:

- [AMWA IS-04 NMOS Discovery and Registration Specification](https://specs.amwa.tv/is-04/) (supporting v1.0-v1.3)
- [AMWA IS-05 NMOS Device Connection Management Specification](https://specs.amwa.tv/is-05/) (supporting v1.0-v1.1)
- [AMWA IS-07 NMOS Event & Tally Specification](https://specs.amwa.tv/is-07/) (supporting v1.0)
- [AMWA IS-08 NMOS Audio Channel Mapping Specification](https://specs.amwa.tv/is-08/) (supporting v1.0)
- [AMWA IS-09 NMOS System Parameters Specification](https://specs.amwa.tv/is-09/) (supporting v1.0)
- [AMWA BCP-002-01 NMOS Grouping Recommendations - Natural Grouping](https://specs.amwa.tv/bcp-002-01/)
- [AMWA BCP-003-01 Secure Communication in NMOS Systems](https://specs.amwa.tv/bcp-003-01/)
- [AMWA BCP-004-01 NMOS Receiver Capabilities](https://specs.amwa.tv/bcp-004-01/)

Additionally it supports the following additional components:

- Supports auto identification of the switch Boundary Clock PTP Domain which is published via the AMWA IS-09 System Resource when run on a Mellanox switch
- Supports an embedded NMOS Browser Client/Controller which supports NMOS Control using AMWA IS-05. This implementation also supports AMWA IS-08 but currently view-only.
- Supports an embedded MQTT Broker (mosquitto) to allow simplified use of the NMOS MQTT Transport type for AMWA IS-05 and IS-07 
- Supports a DNS-SD Bridge to HTML implementation that supports both mDNS and DNS-SD

The nmos-cpp container includes implementations of the NMOS Node, Registration and Query APIs, and the NMOS Connection API. It also included a NMOS Browser Client/Controller in JavaScript, a MQTT Broker and a DNS-SD API which aren't part of the specifications.

## Container Testing, supported architectures and Release Notes

### JT-NM Tested

[<img alt="JT-NM Tested 03/20 NMOS & TR-1001-1 Controller" src="https://github.com/rhastie/build-nmos-cpp/blob/master/images/jt-nm-org_tested_NMOS-TR-CONTROLLERS_03-20_badge.png?raw=true" height="120" align="right"/>](https://jt-nm.org/jt-nm_tested/)[<img alt="JT-NM Tested 03/20 NMOS & TR-1001-1" src="https://github.com/rhastie/build-nmos-cpp/blob/master/images/jt-nm-org_self-tested_NMOS-TR_03-20_badge.png?raw=true" height="120" align="right"/>](https://jt-nm.org/jt-nm_tested/)

The NVIDIA NMOS docker container has now passed the stringent testing required by JT-NM for both Registries and Controllers. The container was tested whilst running on a Mellanox Spectrum/Spectrum-2 switch using the Onyx Docker subsystem. You can access the [JT-NM testing matrix here](https://www.jt-nm.org/documents/JT-NM_Tested_Catalog_NMOS-TR-1001_Full-Online-2020-05-12.pdf).

In addition, the container has been successfully tested in AMWA Networked Media Incubator workshops.

### Tested Platforms and supported CPU Architectures

The Dockerfile in this repository is designed so that if needed it can be run under the Docker Experimental BuildX CLI feature set. The container is published for the follow CPU Architectures:

- Intel and AMD x86_86 64-bit architectures
- ARMv8 AArch64 (64-bit ARM architecture)
- ARMv7 AArch32 (32-bit ARM architecture)

The container has been tested on the following platforms for compatibility:

- Mellanox SN2000, SN3000 and SN4000 Series switches
- Mellanox Bluefield family of SmartNICs (operating natively on the SmartNIC ARM cores)
- NVIDIA Jetson AGX Xavier Developer Kit (even though not tested the container should function on all NVIDIA AGX platforms)
- Raspberry Pi RPi 3 Model B and RPi 4 Model B (both Raspbian's standard 32-bit and the new experimental 64-bit kernels have been tested)
- Standard Intel and AMD Servers running the container under Ubuntu Linux and Windows - Both bare-metal and virtualised environments have been tested. 

### Continuous Integration (CI) Testing

The NVIDIA NMOS container, like the NMOS Specifications, is intended to be always ready, but continually developing.
To ease development overheads and to continually validate the status of the container it now undergoes CI Testing via GitHub Actions.
This CI testing is meant as a sanity check around the container functionality rather than extensive testing of nmos-cpp functionality itself.
Please see wider [Sony CI Testing](https://github.com/sony/nmos-cpp/blob/master/README.md#build-status) for deeper testing on nmos-cpp.

The following configuration, defined by the [ci-build-test-publish](.github/workflows/ci-build-test-publish.yml) job, is built and unit tested automatically via continuous integration. If the tests complete successfully the container is published directly to Docker Hub and also saved as an artifact against the GitHub Action Job. Additional configurations may be added in the future.

| Platform | Version                  | Configuration Options                  |
|----------|--------------------------|----------------------------------------|
| Linux    | Ubuntu 18.04 (GCC 7.5.0) | Avahi                                  |

The [AMWA NMOS API Testing Tool](https://github.com/AMWA-TV/nmos-testing) is automatically run against the built **NMOS container** operating in both "nmos-node" and "nmos-registry" configurations.

**Test Suite Result/Status:**

[![IS-04-01][IS-04-01-badge]][IS-04-01-sheet]
[![IS-04-02][IS-04-02-badge]][IS-04-02-sheet]
[![IS-04-03][IS-04-03-badge]][IS-04-03-sheet]
[![IS-05-01][IS-05-01-badge]][IS-05-01-sheet]
[![IS-05-02][IS-05-02-badge]][IS-05-02-sheet]
[![IS-07-01][IS-07-01-badge]][IS-07-01-sheet]
[![IS-07-02][IS-07-02-badge]][IS-07-02-sheet]
[![IS-08-01][IS-08-01-badge]][IS-08-01-sheet]
[![IS-08-02][IS-08-02-badge]][IS-08-02-sheet]
[![IS-09-01][IS-09-01-badge]][IS-09-01-sheet]
[![IS-09-02][IS-09-02-badge]][IS-09-02-sheet]
[![MQTT-Broker][MQTT-Broker-badge]][MQTT-Broker-link]

[IS-04-01-badge]: https://github.com/rhastie/build-nmos-cpp/blob/badges/IS-04-01.svg?raw=true
[IS-04-02-badge]: https://github.com/rhastie/build-nmos-cpp/blob/badges/IS-04-02.svg?raw=true
[IS-04-03-badge]: https://github.com/rhastie/build-nmos-cpp/blob/badges/IS-04-03.svg?raw=true
[IS-05-01-badge]: https://github.com/rhastie/build-nmos-cpp/blob/badges/IS-05-01.svg?raw=true
[IS-05-02-badge]: https://github.com/rhastie/build-nmos-cpp/blob/badges/IS-05-02.svg?raw=true
[IS-07-01-badge]: https://github.com/rhastie/build-nmos-cpp/blob/badges/IS-07-01.svg?raw=true
[IS-07-02-badge]: https://github.com/rhastie/build-nmos-cpp/blob/badges/IS-07-02.svg?raw=true
[IS-08-01-badge]: https://github.com/rhastie/build-nmos-cpp/blob/badges/IS-08-01.svg?raw=true
[IS-08-02-badge]: https://github.com/rhastie/build-nmos-cpp/blob/badges/IS-08-02.svg?raw=true
[IS-09-01-badge]: https://github.com/rhastie/build-nmos-cpp/blob/badges/IS-09-01.svg?raw=true
[IS-09-02-badge]: https://github.com/rhastie/build-nmos-cpp/blob/badges/IS-09-02.svg?raw=true
[MQTT-Broker-badge]: https://github.com/rhastie/build-nmos-cpp/blob/badges/MQTT-Broker.svg?raw=true
[IS-04-01-sheet]: https://docs.google.com/spreadsheets/d/1xtxALyCpr5cR4zHwjnW12b8wAOf2uvL0QBLFCPgdE1A/edit#gid=0
[IS-04-02-sheet]: https://docs.google.com/spreadsheets/d/1xtxALyCpr5cR4zHwjnW12b8wAOf2uvL0QBLFCPgdE1A/edit#gid=1838684224
[IS-04-03-sheet]: https://docs.google.com/spreadsheets/d/1xtxALyCpr5cR4zHwjnW12b8wAOf2uvL0QBLFCPgdE1A/edit#gid=1174955447
[IS-05-01-sheet]: https://docs.google.com/spreadsheets/d/1xtxALyCpr5cR4zHwjnW12b8wAOf2uvL0QBLFCPgdE1A/edit#gid=517163955
[IS-05-02-sheet]: https://docs.google.com/spreadsheets/d/1xtxALyCpr5cR4zHwjnW12b8wAOf2uvL0QBLFCPgdE1A/edit#gid=205041321
[IS-07-01-sheet]: https://docs.google.com/spreadsheets/d/1xtxALyCpr5cR4zHwjnW12b8wAOf2uvL0QBLFCPgdE1A/edit#gid=828991990
[IS-07-02-sheet]: https://docs.google.com/spreadsheets/d/1xtxALyCpr5cR4zHwjnW12b8wAOf2uvL0QBLFCPgdE1A/edit#gid=367400040
[IS-08-01-sheet]: https://docs.google.com/spreadsheets/d/1xtxALyCpr5cR4zHwjnW12b8wAOf2uvL0QBLFCPgdE1A/edit#gid=2053447021
[IS-08-02-sheet]: https://docs.google.com/spreadsheets/d/1xtxALyCpr5cR4zHwjnW12b8wAOf2uvL0QBLFCPgdE1A/edit#gid=1817945171
[IS-09-01-sheet]: https://docs.google.com/spreadsheets/d/1xtxALyCpr5cR4zHwjnW12b8wAOf2uvL0QBLFCPgdE1A/edit#gid=919453974
[IS-09-02-sheet]: https://docs.google.com/spreadsheets/d/1xtxALyCpr5cR4zHwjnW12b8wAOf2uvL0QBLFCPgdE1A/edit#gid=2135469955
[MQTT-Broker-link]: https://mosquitto.org/man/mosquitto-8.html

### Release Notes and Versioning

The NVIDIA NMOS docker container even though it is continuously being developed we endeavour to make packages available at various major points. [Docker Hub](https://hub.docker.com/r/rhastie/nmos-cpp/tags?page=1&ordering=last_updated) always provides a list of various tags which relate as follows:

- latest - Will always map to the very latest formally released version of the container.
- 1.XY-CCCCCCC - Where X is a number, Y is a letter and C is a nmos-cpp commit reference - Mulit-arch, formal release that has been published post testing. These versions will be preserved as long as Docker Hub allows
- dev-CCCCCCC - Where C is a nmos-cpp commit reference - None multi-arch, dev branch testing - This version should not be relied upon and can be removed without notice.
- master-CCCCCCC - Where C is a nmos-cpp commit reference - None multi-arch, master branch testing - This version should not be relied upon can be removed without notice.
- 0.1X - Where X is a letter - Legacy versions of the container before it was formally released.

In addition to Docker Hub we also maintain an aligned set of release pacakges on GitHub - [NVIDIA NMOS Docker container releases](https://github.com/rhastie/build-nmos-cpp/releases)

For the formally released versions of the container you can follow the [Release Notes](https://github.com/rhastie/build-nmos-cpp/blob/master/Release-Notes.md) documentation to see what has changed.

## How to install and run the container NMOS Registry/Controller

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

- It's generally recommended to use the Ubuntu 20.04+ based BFB (Bluefield bootstream) image as this contains all necessary drivers and OS as a single bundle. See [download page](https://www.mellanox.com/products/software/bluefield)
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

- It's generally recommended to run the very latest JetPack from NVIDIA (JetPack 4.6 at the time of testing)
- Have an accurate date and time
- Docker is generally provided under the NVIDIA JetPack image, but if not available, install a full Docker CE environment using [instructions](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- Set [docker permission](https://superuser.com/questions/835696/how-solve-permission-problems-for-docker-in-ubuntu#853682) for your host user

Execute the follow Linux commands to download and run the container on the host:

```sh
docker pull rhastie/nmos-cpp:latest
docker run -it --net=host --privileged --rm rhastie/nmos-cpp:latest
```

### Raspberry Pi Models 3B, 3B+, 3A+, 4, 400, CM3, CM3+, CM4 and Zero 2 W

Prerequisites:

- It's generally recommended to run the latest version of [Raspberry Pi OS 64-bit](https://downloads.raspberrypi.org/raspios_arm64/images/) (Bullseye at the time of testing)
- Have an accurate date and time
- If using Raspberry Pi OS 64-bit Bullseye you can installed Docker using "sudo apt-get install docker.io". If using older versions of Raspbian install a full Docker CE environment using [instructions](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
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

## Accessing the NMOS Web GUI Interface

The container publishes on all available IP addresses using port 8010

- Browse to http://[Switch or Host IP Address>]:8010 to get to the Web GUI interface.
- The NMOS Registry is published on the "x-nmos" URL
- The NMOS Browser Client/Controller is published on the "admin" URL


## Running the NMOS Virtual Node implementation

The container also contains an implementation of NMOS Virtual Node. This can simulate a node attaching to the registry/controller. Importantly, a single instance of the container can run the registry/controller or the node, but not both at the same time. If you need both operating, you just start a second instance of the container.

By design the container is configured not to run the node implementation by default, however, you can override this default using two different approaches:

### Using an environment variable

There is a docker environmental variable available that will override the default execution of the container and start the NMOS Virtual node. Use the following command to start the container using this variable:

```sh
docker run -it --net=host --name nmos-registry --rm -e "RUN_NODE=TRUE" rhastie/nmos-cpp:latest
```

### Building the container and altering the default execution

You can use the process below to build the container so that the default execution is changed and the container executes the NMOS Virtual Node at runtime without needing an environmental variable being set


## How to build the container

Below are some brief instructions on how to build the container. There are several additional commands available and its suggested you review the Makefile in the repository

### Building the default container for NMOS Registry/Controller execution

- Make sure you have a fully functioning Docker CE environment. It is recommended you follow [the instructions for Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- Clone this repository to your host
- Run:

```sh
make build
```

### Building the container for NMOS Virtual Node execution

- Make sure you have a fully functioning Docker CE environment. It is recommended you follow [the instructions for Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- Clone this repository to your host
- Run:

```sh
make buildnode
```
Please note the container will be built with a “-node” suffix applied to remove any confusion.
