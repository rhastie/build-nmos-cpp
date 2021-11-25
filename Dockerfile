FROM ubuntu:bionic as stage1-build
MAINTAINER rhastie@nvidia.com
LABEL maintainer="rhastie@nvidia.com"

ARG makemt

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends \
    g++ build-essential \
    openssl libssl-dev git wget gnupg curl ca-certificates nano \
    python3 python3-pip python3-setuptools && \
# Avahi:    dbus avahi-daemon libavahi-compat-libdnssd-dev libnss-mdns AND NOT make \
    curl -sS -k "https://dl.yarnpkg.com/debian/pubkey.gpg" | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get update && apt-get install -y --no-install-recommends yarn nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean -y --no-install-recommends && \
    apt-get autoclean -y --no-install-recommends

## Get and Make CMake version 3.22.0 (latest GA when Dockerfile developed) - Adjust as necessary
RUN cd /home/ && wget --no-check-certificate https://cmake.org/files/v3.22/cmake-3.22.0.tar.gz && \
    tar xvf cmake-3.22.0.tar.gz && rm cmake-3.22.0.tar.gz && cd /home/cmake-3.22.0 && \
    if [ -n "$makemt" ]; then echo "Bootstrapping multi-threaded with $makemt jobs"; ./bootstrap --parallel=$makemt; else echo "Bootstrapping single-threaded"; ./bootstrap; fi && \
    if [ -n "$makemt" ]; then echo "Making multi-threaded with $makemt jobs"; make -j$makemt; else echo "Making single-threaded"; make; fi && \
    make install

## Get Conan v1.42.x and it's dependencies
RUN cd /home/ && git config --global http.sslVerify false && \
    git clone --branch release/1.42 https://github.com/conan-io/conan.git && \
    pip3 install --upgrade setuptools && \
    cd conan && pip3 install wheel && pip3 install -e . && export PYTHONPATH=$PYTHONPATH:$(pwd) && \
    export PYTHONPATH=$PYTHONPATH:$(pwd)

## Get Certificates and scripts from AMWA-TV/nmos-testing
RUN cd /home && mkdir certs && git config --global http.sslVerify false && \
    git clone https://github.com/AMWA-TV/nmos-testing.git && \
    mv /home/nmos-testing/test_data/BCP00301/ca/* /home/certs && \
    rm -rf /home/nmos-testing

## Get source for Sony nmos-cpp/
ENV NMOS_CPP_VERSION=95536ae32341046dabf66286b373d70e97e3a59a
RUN cd /home/ && curl --output - -s -k https://codeload.github.com/sony/nmos-cpp/tar.gz/$NMOS_CPP_VERSION | tar zxvf - -C . && \
    mv ./nmos-cpp-${NMOS_CPP_VERSION} ./nmos-cpp

## You should use either Avahi or Apple mDNS - DO NOT use both
##
## mDNSResponder 878.260.1 Build and install
RUN cd /home/ && wget --no-check-certificate https://opensource.apple.com/tarballs/mDNSResponder/mDNSResponder-878.260.1.tar.gz && \
    tar xvf mDNSResponder-878.260.1.tar.gz && rm mDNSResponder-878.260.1.tar.gz && \
    patch -d mDNSResponder-878.260.1/ -p1 <nmos-cpp/Development/third_party/mDNSResponder/unicast.patch && \
    patch -d mDNSResponder-878.260.1/ -p1 <nmos-cpp/Development/third_party/mDNSResponder/permit-over-long-service-types.patch && \
    patch -d mDNSResponder-878.260.1/ -p1 <nmos-cpp/Development/third_party/mDNSResponder/poll-rather-than-select.patch && \
    cd /home/mDNSResponder-878.260.1/mDNSPosix && make os=linux && make os=linux install

## Build Sony nmos-cpp from sources
RUN mkdir /home/nmos-cpp/Development/build && \
    cd /home/nmos-cpp/Development/build && \
    cmake \
    -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE:STRING="MinSizeRel" \
    -DCMAKE_CONFIGURATION_TYPES:STRING="MinSizeRel" \
    -DCXXFLAGS:STRING="-Os" \
    -DNMOS_CPP_USE_AVAHI:BOOL="0" \
    /home/nmos-cpp/Development/build .. && \
    if [ -n "$makemt" ]; then echo "Making multi-threaded with $makemt jobs"; make -j$makemt; else echo "Making single-threaded"; make; fi

## Generate Example Certificates and position into correct locations
RUN cd /home/certs && mkdir run-certs && ./generateCerts registration1 nmos.tv query1.nmos.tv && \
    cd /home/certs/certs && \
    cp ca.cert.pem /home/certs/run-certs/ca.cert.pem && \
    cd /home/certs/intermediate/certs && \
    mv ecdsa.registration1.nmos.tv.cert.chain.pem /home/certs/run-certs/ecdsa.cert.chain.pem && \
    mv rsa.registration1.nmos.tv.cert.chain.pem /home/certs/run-certs/rsa.cert.chain.pem && \
    cd /home/certs/intermediate/private && \
    mv ecdsa.registration1.nmos.tv.key.pem /home/certs/run-certs/ecdsa.key.pem && \
    mv rsa.registration1.nmos.tv.key.pem /home/certs/run-certs/rsa.key.pem && \
    cp dhparam.pem /home/certs/run-certs/dhparam.pem

## Create relevant configuration files for Sony Registry and Node
RUN cd /home/ && mkdir example-conf && mkdir admin
ADD example-conf /home/example-conf

## Get and build source for Sony nmos-js
RUN cd /home/ && git config --global http.sslVerify false && git clone https://github.com/sony/nmos-js.git

## Custom branding
COPY NVIDIA_Logo_H_ForScreen_ForLightBG.png nmos-js.patch /home/nmos-js/Development/src/assets/
RUN cd /home && \
    mv /home/nmos-js/Development/src/assets/nmos-js.patch /home && \
    patch -p0 <nmos-js.patch && \
    rm /home/nmos-js/Development/src/assets/sea-lion.png && \
    rm nmos-js.patch

## Build and install Sony nmos-js
RUN cd /home/nmos-js/Development && \
    yarn install --network-timeout 1000000 && \
    yarn build && \
    cp -rf /home/nmos-js/Development/build/* /home/admin

## Move executables, libraries and clean up container as much as possible
RUN cd /home/nmos-cpp/Development/build && \
    cp nmos-cpp-node nmos-cpp-registry /home && \
    cd /home && rm -rf .git conan cmake-3.22.0 nmos-cpp nmos-js

## Re-build container for optimised runtime environment using clean Ubuntu Bionic release
FROM ubuntu:bionic

##Copy required files from build container
COPY --from=stage1-build /home /home

##Update container with latest patches and needed packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends \
    openssl make nano curl jq gnupg && \
# Avahi:    dbus avahi-daemon libavahi-compat-libdnssd-dev libnss-mdns AND NOT make \
    cd /home/mDNSResponder-878.260.1/mDNSPosix && make os=linux install && \
    cd /home && rm -rf /home/mDNSResponder-878.260.1 /etc/nsswitch.conf.pre-mdns && \
    curl -sS -k "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x77b7346a59027b33c10cafe35e64e954262c4500" | apt-key add - && \
    echo "deb http://ppa.launchpad.net/mosquitto-dev/mosquitto-ppa/ubuntu bionic main" | tee /etc/apt/sources.list.d/mosquitto.list && \
    apt-get update && apt-get install -y --no-install-recommends mosquitto && \
    apt-get remove --purge -y make gnupg && \
    apt-get autoremove -y && \
    apt-get clean -y --no-install-recommends && \
    apt-get autoclean -y --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/doc/ && rm -rf /usr/share/man/ && rm -rf /usr/share/locale/ && \
    rm -rf /usr/local/share/man/* && rm -rf /usr/local/share/.cache/*

##Copy entrypoint.sh script and master config to image
COPY entrypoint.sh container-config registry.json node.json /home/

##Set script to executable
RUN chmod +x /home/entrypoint.sh

##Set default config variable to run registry (FALSE) or node (TRUE)
ARG runnode=FALSE
ENV RUN_NODE=$runnode

WORKDIR /home/
ENTRYPOINT ["/home/entrypoint.sh"]
#CMD []
