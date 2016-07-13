FROM ubuntu:xenial

ENV PATH ${PATH}:/usr/local/go/bin
ENV GOPATH ${HOME}/go
ENV SRC_PATH ${GOPATH}/src/amqp-echo
ENV DATA_HOME /data/

ADD . ${SRC_PATH}

RUN \
    adduser --disabled-password --gecos '' runner && \
    DEBIAN_FRONTEND=noninteractive apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
    dpkg -l > /var/tmp/dpkg_pre_deps.txt && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install wget git && \
    wget -nv --no-check-certificate https://storage.googleapis.com/golang/go1.6.2.linux-amd64.tar.gz && \
    shasum -a 256 go1.6.2.linux-amd64.tar.gz | grep e40c36ae71756198478624ed1bb4ce17597b3c19d243f3f0899bb5740d56212a && \
    tar -C /usr/local -xzf go1.6.2.linux-amd64.tar.gz && \
    rm -f go1.6.2.linux-amd64.tar.gz && \
    mkdir -p ${GOPATH}/{src,bin,pkg} && \
    cd ${SRC_PATH} && \
    go get github.com/streadway/amqp && \
    go build && \
    mkdir -p ${DATA_HOME} && \
    mv amqp-echo ${DATA_HOME} && cp run.sh ${DATA_HOME} && chmod +x ${DATA_HOME}* && \
    cd ${HOME} && \
    rm -rf ${GOPATH} && \
    rm -rf /usr/local/go && \
    chown -Rf runner:runner /data && \
    DEBIAN_FRONTEND=noninteractive apt-get purge -y --auto-remove wget git perl perl-modules-5.22 less rename && \
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y --purge && \
    DEBIAN_FRONTEND=noninteractive apt-get clean -y && \
    dpkg -l > /var/tmp/dpkg_post_deps.txt && \
    diff /var/tmp/dpkg_pre_deps.txt /var/tmp/dpkg_post_deps.txt && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV GOPATH= SRC_PATH=

USER runner
WORKDIR /data/

ENTRYPOINT ["/data/run.sh"]
CMD [""]