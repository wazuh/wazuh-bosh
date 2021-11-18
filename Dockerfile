FROM ubuntu:xenial
ARG VERSION=4.2.3
RUN apt-get update && \
    apt-get install git -y
RUN apt-get install python gcc g++ make libc6-dev curl policycoreutils automake autoconf libtool libssl-dev -y
WORKDIR /root
RUN curl -OL https://packages.wazuh.com/utils/cmake/cmake-3.18.3.tar.gz && tar -zxf cmake-3.18.3.tar.gz 
WORKDIR /root/cmake-3.18.3 
RUN ./bootstrap --no-system-curl
RUN make -j$(nproc) && make install
WORKDIR /root
RUN rm -rf cmake-*
RUN apt-get install -y lsb-release && \
    echo "deb-src http://archive.ubuntu.com/ubuntu/ $(lsb_release -cs) main" >> /etc/apt/sources.list  && \
    apt-get update  && \
    apt-get build-dep python3.5 -y
RUN curl -Ls https://github.com/wazuh/wazuh/archive/refs/tags/v$VERSION.tar.gz | tar xz
RUN mv wazuh-*/ wazuh
COPY create_binaries.sh /root/

CMD ["/root/create_binaries.sh"]
