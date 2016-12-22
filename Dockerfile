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
    wget -q https://releases.hashicorp.com/consul/0.7.1/consul_0.7.1_linux_amd64.zip &&\
    wget -q https://releases.hashicorp.com/consul/0.7.1/consul_0.7.1_web_ui.zip &&\
    unzip consul_0.7.1_linux_amd64.zip &&\
    unzip -d dist consul_0.7.1_web_ui.zip &&\
    mv consul /usr/bin &&\
    mkdir -p /var/www/consul &&\
    mv dist/* /var/www/consul/ &&\
    rm -r dist consul_0.7.1_linux_amd64.zip consul_0.7.1_web_ui.zip



# Add scripts
COPY run.sh /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["run.sh"]