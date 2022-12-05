# AMWA NMOS Containerised Registry, Browser Client/Controller and Node Container Release Notes

**Build status:** [![ci-build-test-publish](https://github.com/rhastie/build-nmos-cpp/workflows/ci-build-test-publish/badge.svg?branch=master)](https://github.com/rhastie/build-nmos-cpp/actions?query=workflow%3Aci-build-test-publish)

## Release Notes by major version

### v1.2 (22 Feb 2021) - Update release
Compiled against the latest Sony nmos-cpp commit (3a57c8f) - Since the last update there has so many changes to the NMOS-CPP code base that I suggest you look at the [Sony GitHub pages](https://github.com/sony/nmos-cpp/commits/master):  
Update to latest dependencies and embedded versions. Applied latest Ubuntu patching  
Added formal support for [AMWA Easy-NMOS](https://github.com/rhastie/easy-nmos)  
Added initial Controller support for AMWA IS-08 NMOS Audio Channel Mapping Specification - View-only currently  
Updated embedded MQTT Broker to support MQTT v5 and secure TLS capabilitie if needed (disabled by default)
Added NMOS Browser Client/Controller configuration at build time
Added support for NVIDIA NGC (NVIDIA GPU Cloud)  
Changed branding to NVIDIA  

### v1.1 (24 Jul 2020) - Update release
Compiled against the latest Sony nmos-cpp commit (b0dcf9d) - Since the last update there has so many changes to the NMOS-CPP code base that I suggest you look at the [Sony GitHub pages](https://github.com/sony/nmos-cpp):  
Update to latest dependencies and embedded versions. Applied latest Ubuntu patching  
Added support for AMWA IS-08 NMOS Audio Channel Mapping Specification (supporting v1.0) in Node  
Added an embedded MQTT Broker (mosquitto) to allow simplified use of the NMOS MQTT Transport type for AMWA IS-05 and IS-07  
Enabled RUN_NODE functionality as detail in README.md

### v1.0 (25 Jun 2020) - Initial release
Compiled against the latest Sony nmos-cpp commit (4a51af5) – Since the last update there has so many changes to the NMOS-CPP code base that I suggest you look at the [Sony GitHub pages](https://github.com/sony/nmos-cpp/commits/master):  
On-switch NMOS Container can now support:
- AMWA IS-04 NMOS Discovery and Registration Specification
- AMWA IS-05 NMOS Connection Management Specification
- AMWA IS-07 NMOS Event & Tally Specification (Mainly Node only but there is a node implementation inside the container)
- AMWA IS-09 NMOS System Specification (originally defined in JT-NM TR-1001-1:2018 Annex A) – Currently defaults to PTP Domain Number 127
- AMWA BCP-002-01 NMOS Grouping Recommendations - Natural Grouping (Mainly Node only but there is a node implementation inside the container)
- AMWA BCP-003-01 NMOS API Security Recommendations - Securing Communications
- Supports JT-NM TR1001 full spec when partnered with the DNS/DHCP container

New In-container configuration files – Two new files “container-config” and “registry-json” which now allows you to change the registry and container config using just the switch commands – Specifically, “docker exec” and “docker commit” – Please contact me if you want to know more 
Container now packaged with parts of the AMWA-TV/nmos-testing repo – Specifically to allow testing of BCP003-001 functionality and certificate generation  
Container now package with the Sony NMOS Registry client (node-js) – Can be access on <registry URL root>/admin. Offers Web-based registry browsing in a usable format  
Consolidated Network Ports – Container now uses port 8008 for everything with the exception of Query WebSocket which is on port 8009 – These are the default settings and they can be adjusted by altering the “registry-json” file  
Updated the entrypoint.sh script – Specifically to utilize the configuration files. Script will be improved over time to automate additional functions such as System Resource (PTP), Hostname and Do  main validation and automatic certificate generation  
New option providing enhanced logging. You will notice there is now one image. There is a new switch in “container-config” that allows you to set whether you want the container to log or not  
Container size optimization – Even though there is loads more functionality this container is now smaller and more efficient to download and run on the switch  
AMWA IS-05 Node functionality is installed but turned off – This implementation has been updated. Mellanox is exploring the use of on-switch IS-05 with our P4 timed-switch/salvo development.

