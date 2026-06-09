ARG BASE_IMAGE=ubuntu:noble
ARG NMOS_CPP_VERSION=079620d88756aa138ede92d3f52a0102370307fe
ARG NMOS_JS_VERSION=331ae7614e1003c4f1a64aeac405eb628190e9d9

############################################################
# Stage 1 — build nmos-cpp, certs, and assemble /home
############################################################
FROM ${BASE_IMAGE} AS stage1-build
LABEL maintainer="rhastie@nvidia.com"

ARG makemt
ARG NMOS_CPP_VERSION

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends \
    g++ build-essential \
    openssl libssl-dev git wget gnupg curl ca-certificates nano \
    python3 python3-venv rdma-core && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean -y --no-install-recommends && \
    apt-get autoclean -y --no-install-recommends

## Install CMake and Conan in a venv (Noble blocks system-wide pip — PEP 668)
RUN python3 -m venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH
RUN pip install --no-cache-dir "cmake~=3.31" "conan~=2.29"

## Get Certificates and scripts from AMWA-TV/nmos-testing
RUN cd /home && mkdir certs && git config --global http.sslVerify false && \
    git clone https://github.com/AMWA-TV/nmos-testing.git && \
    mv /home/nmos-testing/test_data/BCP00301/ca/* /home/certs && \
    rm -rf /home/nmos-testing

## Get source for Sony nmos-cpp
## Commit 079620d corresponds to Conan package nmos-cpp/cci.20260602
RUN cd /home/ && curl --output - -s -k https://codeload.github.com/sony/nmos-cpp/tar.gz/${NMOS_CPP_VERSION} | tar zxvf - -C . && \
    mv ./nmos-cpp-${NMOS_CPP_VERSION} ./nmos-cpp

## You should use either Avahi or Apple mDNS - DO NOT use both
##
## mDNSResponder 878.260.1 Build and install
RUN cd /home/ && curl --output - -s -k https://codeload.github.com/apple-oss-distributions/mDNSResponder/tar.gz/mDNSResponder-878.260.1 | tar zxvf - -C . && \
    mv ./mDNSResponder-mDNSResponder-878.260.1 ./mDNSResponder && \
    patch -d mDNSResponder/ -p1 <nmos-cpp/Development/third_party/mDNSResponder/unicast.patch && \
    patch -d mDNSResponder/ -p1 <nmos-cpp/Development/third_party/mDNSResponder/permit-over-long-service-types.patch && \
    patch -d mDNSResponder/ -p1 <nmos-cpp/Development/third_party/mDNSResponder/poll-rather-than-select.patch && \
    cd /home/mDNSResponder/mDNSPosix && HAVE_IPV6=0 make os=linux && make os=linux install

## Build Sony nmos-cpp from sources
RUN conan profile detect --force \
    && cmake -S /home/nmos-cpp/Development -B /home/nmos-cpp/Development/build \
        -G "Unix Makefiles" \
        -DCMAKE_PROJECT_TOP_LEVEL_INCLUDES=third_party/cmake/conan_provider.cmake \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCXXFLAGS=-Os \
        -DNMOS_CPP_USE_AVAHI=OFF \
        -DNMOS_CPP_BUILD_EXAMPLES=ON \
        -DNMOS_CPP_BUILD_TESTS=OFF \
    && cmake --build /home/nmos-cpp/Development/build \
        --target nmos-cpp-registry nmos-cpp-node \
        --parallel ${makemt:-$(nproc)}

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

## Move executables, libraries and clean up container as much as possible
RUN cd /home/nmos-cpp/Development/build && \
    cp nmos-cpp-node nmos-cpp-registry /home && \
    cd /home && rm -rf .git nmos-cpp

############################################################
# Stage 2 — build the nmos-js browser UI (static files)
############################################################
FROM node:20-bookworm-slim AS js-build

ARG NMOS_JS_VERSION
# Do not fail the build on lint warnings, and skip source maps to save space.
ENV CI=false
ENV GENERATE_SOURCEMAP=false

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates patch \
    && rm -rf /var/lib/apt/lists/*

## Get source for Sony nmos-js
WORKDIR /home
RUN curl --output - -fsSL https://codeload.github.com/sony/nmos-js/tar.gz/${NMOS_JS_VERSION} | tar zx -C . \
    && mv ./nmos-js-${NMOS_JS_VERSION} ./nmos-js

## Custom branding
COPY NVIDIA_Logo_H_ForScreen_ForLightBG.png nmos-js.patch /home/nmos-js/Development/src/assets/
RUN mv /home/nmos-js/Development/src/assets/nmos-js.patch /home/nmos-js.patch \
    && patch -p0 < /home/nmos-js.patch \
    && rm /home/nmos-js/Development/src/assets/sea-lion.png \
    && rm /home/nmos-js.patch

## Build and install Sony nmos-js
WORKDIR /home/nmos-js/Development
RUN corepack enable \
    && yarn install --network-timeout 1000000 \
    && yarn build \
    && mkdir -p /admin && cp -rf build/* /admin/

############################################################
# Stage 3 — slim runtime image
############################################################
## Re-build container for optimised runtime environment using clean base image
FROM ${BASE_IMAGE}

##Copy required files from build container
COPY --from=stage1-build /home /home
COPY --from=js-build /admin /home/admin

##Update container with latest patches and needed packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends \
    openssl make nano curl jq rdma-core mosquitto && \
# Avahi:    dbus avahi-daemon libavahi-compat-libdnssd-dev libnss-mdns AND NOT make \
    cd /home/mDNSResponder/mDNSPosix && make os=linux install && \
    cd /home && rm -rf /home/mDNSResponder /etc/nsswitch.conf.pre-mdns && \
    apt-get remove --purge -y make && \
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

##Expose correct default ports to allow quick publishing
EXPOSE 8010 8011 11000 11001 1883 5353/udp

WORKDIR /home/
ENTRYPOINT ["/home/entrypoint.sh"]
#CMD []
