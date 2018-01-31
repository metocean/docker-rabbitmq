FROM rabbitmq:3.6-management
MAINTAINER Andre Lobato <andre@metocean.co.nz>

# Install utils
RUN apt-get update --fix-missing && \
    apt-get install -y wget unzip dnsutils && \
    apt-get clean

# Install consul
RUN echo "-----------------Install Consul-----------------" &&\
    cd /tmp &&\
    mkdir /consul &&\
    wget -q https://releases.hashicorp.com/consul/1.0.3/consul_1.0.3_linux_amd64.zip &&\
    unzip consul_1.0.3_linux_amd64.zip &&\
    mv consul /usr/bin &&\
    rm -r consul_1.0.3_linux_amd64.zip

# Add scripts
COPY run.sh /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["run.sh"]