FROM centos:7.6.1810
MAINTAINER Syhily, syhily@gmail.com

# Docker Build Arguments, For further upgrade
ENV ORANGE_PATH="/usr/local/orange"
ARG LOR_VERSION="0.3.4"
ENV ORANGE_VERSION="0.7.0"

ADD docker-entrypoint.sh docker-entrypoint.sh

#  1) Set the bootstrap scripts
#  2) Install yum dependencies
#  3) Cleanup
#  4) Install lor
#  5) Install orange
#  6) Cleanup
#  7) dnsmasq
#  8) Add User
#  9) Add configuration file & bootstrap file
# 10) Fix file permission
RUN \
    chmod 755 docker-entrypoint.sh \
    && mv docker-entrypoint.sh /usr/local/bin

RUN \
    yum-config-manager --add-repo https://openresty.org/yum/cn/centos/OpenResty.repo \
    && yum install -y epel-release
RUN \
    yum install -y dnsmasq openresty openresty-resty make telnet \

    && yum clean all

RUN \
    ln -s /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx

    #
RUN mkdir -p /home/docker
COPY lor-${LOR_VERSION}.tar.gz /home/docker/lor.tar.gz
COPY orange-${ORANGE_VERSION}.tar.gz /home/docker/orange.tar.gz
RUN \
    cd /home/docker \
#    && curl -fSL https://github.com/sumory/lor/archive/v${LOR_VERSION}.tar.gz -o lor.tar.gz \
    && tar zxf lor.tar.gz \
    && cd lor-${LOR_VERSION} \
    && make install

RUN \
    cd  /home/docker \
#    && curl -fSL https://github.com/sumory/orange/archive/v${ORANGE_VERSION}.tar.gz -o orange.tar.gz \
    && tar zxf orange.tar.gz \
    && cd orange-${ORANGE_VERSION} \
    && make install \

    && cd / \
    && rm -rf /home/docker/* \

    && echo "user=root" > /etc/dnsmasq.conf \
    && echo 'domain-needed' >> /etc/dnsmasq.conf \
    && echo 'listen-address=127.0.0.1' >> /etc/dnsmasq.conf \
    && echo 'resolv-file=/etc/resolv.dnsmasq.conf' >> /etc/dnsmasq.conf \
    && echo 'conf-dir=/etc/dnsmasq.d' >> /etc/dnsmasq.conf \
    # This upstream dns server will cause some issues
    && echo 'INTERNAL_DNS' >> /etc/resolv.dnsmasq.conf \
    && echo 'nameserver 8.8.8.8' >> /etc/resolv.dnsmasq.conf \
    && echo 'nameserver 8.8.4.4' >> /etc/resolv.dnsmasq.conf \

    && useradd www \
    && echo "www:www" | chpasswd \
    && echo "www   ALL=(ALL)       ALL" >> /etc/sudoers \
    && mkdir -p ${ORANGE_PATH}/logs \
    && chown -R www:www ${ORANGE_PATH}/*

EXPOSE 7777 80 9999

# Daemon
ENTRYPOINT ["docker-entrypoint.sh"]
