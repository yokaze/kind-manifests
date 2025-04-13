FROM ghcr.io/cybozu/ubuntu-dev:24.04 AS builder
ARG TAG=SQUID_6_13
WORKDIR /work
RUN apt-get update && apt-get install -y autoconf libtool
RUN curl -L https://github.com/squid-cache/squid/archive/refs/tags/${TAG}.tar.gz \
    | tar zxf - --strip-components=1
RUN /work/bootstrap.sh \
    && ./configure \
        --with-logdir=/var/log/squid \
        --with-openssl \
        --with-pidfile=/var/run/squid.pid \
        --with-swapdir=/var/cache/squid \
    && make -j$(nproc)
RUN make install

FROM ghcr.io/cybozu/ubuntu:24.04
RUN apt-get update && apt-get install -y libltdl7 --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/squid /usr/local/squid
RUN mkdir -p /var/cache/squid && chown proxy:proxy /var/cache/squid && \
    mkdir -p /var/log/squid && chown proxy:proxy /var/log/squid && \
    mkdir -p /var/run && chown proxy:proxy /var/run

USER proxy:proxy
ENV PATH=/usr/local/squid/sbin:${PATH}
ENTRYPOINT ["/usr/local/squid/sbin/squid", "-N"]
