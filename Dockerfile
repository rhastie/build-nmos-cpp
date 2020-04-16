FROM ubuntu:bionic as stage1-build
MAINTAINER richh@mellanox.com
LABEL maintainer="richh@mellanox.com"

ARG makemt

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn \
    NMOS_CPP_VERSION=b30c1a98670aa05f5b35c7b5340c5ec5893df508

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends \
    g++ build-essential \
    openssl libssl-dev git wget gnupg curl ca-certificates nano \
    python3 python3-pip python3-setuptools && \
# Avahi:    dbus avahi-daemon libavahi-compat-libdnssd-dev libnss-mdns AND NOT make \
    curl -sS -k https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y --no-install-recommends yarn nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean -y --no-install-recommends && \
    apt-get autoclean -y --no-install-recommends

## Get and Make CMake version 3.17.2 (latest when Dockerfile developed) - Adjust as necessary
RUN cd /home/ && wget --no-check-certificate https://cmake.org/files/v3.17/cmake-3.17.2.tar.gz && \
    tar xvf cmake-3.17.2.tar.gz && rm cmake-3.17.2.tar.gz && cd /home/cmake-3.17.2 && \
    ./bootstrap && \
    if [ -n "$makemt" ]; then echo "Making multi-threaded with $makemt jobs"; make -j$makemt; else echo "Making single-threaded"; make; fi && \
    make install

## Get Conan and it's dependencies
RUN cd /home/ && git config --global http.sslVerify false && \
git clone --branch release/1.24 https://github.com/conan-io/conan.git && \
cd conan && pip3 install wheel && pip3 install -e . && export PYTHONPATH=$PYTHONPATH:$(pwd) && \
export PYTHONPATH=$PYTHONPATH:$(pwd)

## Get Certificates and scripts from AMWA-TV/nmos-testing
RUN cd /home && mkdir certs && git config --global http.sslVerify false && \
    git clone https://github.com/AMWA-TV/nmos-testing.git && \
    mv /home/nmos-testing/test_data/BCP00301/ca/* /home/certs && \
    rm -rf /home/nmos-testing

## Get source for Sony nmos-cpp/
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

## Patch conanfile.txt so that OpenSSL version is aligned to the current distribution version
#RUN openssl version && cd /home/nmos-cpp/Development && \
#    openssl version | cut -d ' ' -f1,2 | sed -e 's/.*/\L&/;s/ /\\\//g' > distsslversion && \
#    sed -i "s/openssl.*/$(cat distsslversion)/g" conanfile.txt && \
#    rm distsslversion

## Build Sony nmos-cpp from sources
RUN mkdir /home/nmos-cpp/Development/build && \
    cd /home/nmos-cpp/Development/build && \
    cmake \
    -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE:STRING="Release" \
    -DCMAKE_CONFIGURATION_TYPES:STRING="Release" \
    -DCXXFLAGS:STRING="-Os" \
    -build /home/nmos-cpp/Development/build .. && \
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
RUN cd /home/ && git config --global http.sslVerify false && \
    git clone https://github.com/sony/nmos-js.git
COPY mellanox-logo-horizontal-blue.png nmos-js.patch /home/nmos-js/Development/src/assets/
RUN cd /home && \
    mv /home/nmos-js/Development/src/assets/nmos-js.patch /home && \
    patch -p0 <nmos-js.patch && \
    rm /home/nmos-js/Development/src/assets/sea-lion.png && \
    rm nmos-js.patch && \
    cd /home/nmos-js/Development && \
    yarn install --network-timeout 1000000 && \
    yarn build && \
    cp -rf /home/nmos-js/Development/build/* /home/admin

## Move executables, libraries and clean up container as much as possible
RUN cd /home/nmos-cpp/Development/build && \
    cp nmos-cpp-node nmos-cpp-registry /home && \
    cd /home && rm -rf .git conan cmake-3.17.2 nmos-cpp nmos-js nmos-web-router

## Re-build container for optimised runtime environment using clean Ubuntu Bionic release

FROM ubuntu:bionic

##Copy required files from build container
COPY --from=stage1-build /home /home

##Update container with latest patches and needed packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends \
    openssl make \
# Avahi:    dbus avahi-daemon libavahi-compat-libdnssd-dev libnss-mdns AND NOT make \
    nano curl jq && \
    cd /home/mDNSResponder-878.260.1/mDNSPosix && make os=linux install && \
    cd /home && rm -rf /home/mDNSResponder-878.260.1 /etc/nsswitch.conf.pre-mdns && \
    apt-get purge -y make && \
    apt-get clean -y --no-install-recommends && \
    apt-get autoclean -y --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/doc/ && rm -rf /usr/share/man/ && rm -rf /usr/share/locale/ && \
    rm -rf /usr/local/share/man/* && rm -rf /usr/local/share/.cache/*

##Copy entrypoint.sh script and master config to image
COPY entrypoint.sh container-config registry-json /home/

##Set script to executable
RUN chmod +x /home/entrypoint.sh

WORKDIR /home/
ENTRYPOINT ["/home/entrypoint.sh"]
#CMD []
