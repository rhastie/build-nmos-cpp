FROM ubuntu:bionic as stage1-build

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

RUN apt-get update && apt-get install -y --no-install-recommends \
    g++ build-essential openssl libssl-dev unzip git wget \
    zlib1g-dev gnupg curl ca-certificates nano && \
# Avahi:    dbus avahi-daemon libavahi-compat-libdnssd-dev libnss-mdns AND NOT make \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y --no-install-recommends yarn nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean -y --no-install-recommends && \
    apt-get autoclean -y --no-install-recommends

## Get and Make OpenSSL 1.1.1b in order to support TLS1.3
#RUN cd /home/ && wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1b.tar.gz && \
#    tar -zxf openssl-1.1.1b.tar.gz && cd openssl-1.1.1b && \
#    ./config shared zlib && \
#    make && make test && make install && \
#    ln -s /usr/local/bin/openssl /usr/bin/openssl && \
#    ldconfig && openssl version && \
#    cd /home/ && rm openssl-1.1.1b.tar.gz && rm -rf /home/openssl-1.1.1b

## Get and Make CMake version 3.16.1 (latest when Dockerfile developed) - Adjust as necessary
RUN cd /home/ && wget --no-check-certificate https://cmake.org/files/v3.16/cmake-3.16.1.tar.gz && \  
    tar xvf cmake-3.16.1.tar.gz && rm cmake-3.16.1.tar.gz && cd /home/cmake-3.16.1 && \
    ./bootstrap && make && make install

## Get and Make Boost 1.69.0 (latest when Dockerfile developed) - Adjust as necessary
RUN cd /home/ && wget --no-check-certificate https://dl.bintray.com/boostorg/release/1.69.0/source/boost_1_69_0.tar.gz && \
    tar xvf boost_1_69_0.tar.gz && rm boost_1_69_0.tar.gz && cd /home/boost_1_69_0 && \
    ./bootstrap.sh b2 --with-toolset=gcc --with-libraries=date_time,regex,system,thread,random,filesystem,chrono,atomic \
    --prefix=. && ./b2

## Get Certificates and scripts from AMWA-TV/nmos-testing                         
RUN cd /home && mkdir certs && git config --global http.sslVerify false && \
    git clone https://github.com/AMWA-TV/nmos-testing.git && \
    mv /home/nmos-testing/test_data/BCP00301/ca/* /home/certs && \
    rm -rf /home/nmos-testing

## Get source for Sony nmos-cpp/
RUN cd /home/ && git init && git config --global http.sslVerify false && \
    git clone https://github.com/sony/nmos-cpp.git

## You should use either Avahi or Apple mDNS - DO NOT use both
## 
## mDNSResponder 878.200.35 Build and install
RUN cd /home/ && wget --no-check-certificate https://opensource.apple.com/tarballs/mDNSResponder/mDNSResponder-878.200.35.tar.gz && \
    tar xvf mDNSResponder-878.200.35.tar.gz && rm mDNSResponder-878.200.35.tar.gz && \
    patch -d mDNSResponder-878.200.35/ -p1 <nmos-cpp/Development/third_party/mDNSResponder/unicast.patch && \
    patch -d mDNSResponder-878.200.35/ -p1 <nmos-cpp/Development/third_party/mDNSResponder/permit-over-long-service-types.patch && \
    patch -d mDNSResponder-878.200.35/ -p1 <nmos-cpp/Development/third_party/mDNSResponder/poll-rather-than-select.patch && \
    cd /home/mDNSResponder-878.200.35/mDNSPosix && make os=linux && make os=linux install

## Get and Make Microsft C++ REST SDK v2.10.14 from Microsoft Archive
RUN cd /home/ && git init && git config --global http.sslVerify false && \
    git clone --recursive --branch v2.10.14 https://github.com/Microsoft/cpprestsdk cpprestsdk-2.10.14 && \
    mkdir /home/cpprestsdk-2.10.14/Release/build && \
    cd /home/cpprestsdk*/Release/build && \
    cmake .. \
    -DCMAKE_BUILD_TYPE:STRING="Release" \
    -DWERROR:BOOL="0" \
    -DBUILD_SAMPLES:BOOL="0" \
    -DBUILD_TESTS:BOOL="0" \
    -DOPENSSL_ROOT_DIR="/usr/lib/x86_64-linux-gnu" \
    -DOPENSSL_LIBRARIES="/usr/lib/x86_64-linux-gnu" \ 
    -DBOOST_INCLUDEDIR:PATH="/home/boost_1_69_0" \
    -DBOOST_LIBRARYDIR:PATH="/home/boost_1_69_0/x64/lib" && \
    make && \
    make install

## Build nmos-cpp from source
RUN mkdir /home/nmos-cpp/Development/build && \
    cd /home/nmos-cpp/Development/build && \
    cmake \
    -G "Unix Makefiles" \
    -DCMAKE_CONFIGURATION_TYPES:STRING="Debug;Release" \
    -DBoost_USE_STATIC_LIBS:BOOL="1" \
    -DBOOST_INCLUDEDIR:PATH="/home/boost_1_69_0" \
    -DBOOST_LIBRARYDIR:PATH="/home/boost_1_69_0/x64/lib" \
    -DWEBSOCKETPP_INCLUDE_DIR:PATH="/home/cpprestsdk-2.10.14/Release/libs/websocketpp" \
    -DCPPREST_INCLUDE_DIR:PATH="/home/cpprestsdk-2.10.14/" \
    -build /home/nmos-cpp/Development/build .. && \
    make

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

RUN cd /home/ && mkdir example-conf && mkdir admin && mkdir admin/router
ADD example-conf /home/example-conf

## Get and build source for Sony nmos-js
RUN cd /home/ && git init && git config --global http.sslVerify false && \
    git clone https://github.com/sony/nmos-js.git && \
    cd /home/nmos-js/Development && \
    yarn install && \
    yarn build && \
    cp -rf /home/nmos-js/Development/build/* /home/admin

## Get and build source for BBC nmos-web-router
#RUN cd /home/ && git init && git config --global http.sslVerify false && \
#    git clone https://github.com/bbc/nmos-web-router && \
#    cd /home/nmos-web-router/ && \
#    yarn install && \
#    yarn build && \
#    cp -rf /home/nmos-web-router/build/* /home/admin/router

## Move executables, libraries and clean up container as much as possible
RUN cd /home/nmos-cpp/Development/build && \
    cp nmos-cpp-node nmos-cpp-registry nmos-cpp-test /home && \
    cp /home/boost_1_69_0/stage/lib/* /usr/local/lib && \
#    cd /home/cmake-3.16.1 && make uninstall && \
    cd /home && rm -rf .git cmake-3.16.1 boost_1_69_0 cpprestsdk-2.10.14 nmos-cpp nmos-js nmos-web-router
#    apt-get remove g++ build-essential unzip git wget yarn ca-certificates nodejs gnupg curl -y --no-install-recommends && \
#    apt-get autoclean -y && \
#    apt-get autoremove -y && \
#    rm -rf /var/lib/apt/lists/* && \
#    rm -rf /usr/share/doc/ && rm -rf /usr/share/man/ && rm -rf /usr/share/locale/ && \
#    rm -rf /usr/local/share/man/* && rm -rf /usr/local/share/.cache/* && rm -rf /usr/local/share/cmake-3.16/*

## Re-build container for optimised runtime environment using clean Ubuntu Disco release

FROM ubuntu:bionic

#Copy required files from build container
COPY --from=stage1-build /home /home
COPY --from=stage1-build /usr/local/lib /usr/local/lib

#Update container with latest patches and needed packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl libssl-dev make \
# Avahi:    dbus avahi-daemon libavahi-compat-libdnssd-dev libnss-mdns AND NOT make \
    zlib1g-dev nano curl jq && \
    cd /home/mDNSResponder-878.200.35/mDNSPosix && make os=linux install && \
    cd /home && rm -rf /home/mDNSResponder-878.200.35 /etc/nsswitch.conf.pre-mdns && \
    apt-get remove -y make && \
    apt-get clean -y --no-install-recommends && \
    apt-get autoclean -y --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/doc/ && rm -rf /usr/share/man/ && rm -rf /usr/share/locale/ && \
    rm -rf /usr/local/share/man/* && rm -rf /usr/local/share/.cache/*

#Copy entrypoint.sh script to image
COPY entrypoint.sh container-config registry-json /home/

#Set script to executable
RUN chmod +x /home/entrypoint.sh

#WORKDIR /home/
#ENTRYPOINT ["/home/entrypoint.sh"]
#CMD []
