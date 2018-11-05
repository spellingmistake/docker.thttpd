FROM alpine:3.8 as builder

ARG VERSION

RUN apk add --no-cache make gcc patch musl-dev automake autoconf curl

WORKDIR /tmp

# alternatively download tar.gz
#RUN curl -o /tmp/thttpd-${VERSION}.tar.gz                           \
#         https://acme.com/software/thttpd/thttpd-${VERSION}.tar.gz
COPY ./assets/build/src/thttpd-${VERSION}.tar.gz /tmp
ADD ./assets/build/patches /patches
RUN mkdir /build
RUN tar xvzf /tmp/thttpd-${VERSION}.tar.gz --strip-components=1  && \
    for i in $(ls -1 /patches/*.patch); do                          \
        patch -p1 --verbose < $i;                                   \
    done                                                         && \
    ./configure                                                  && \
    make CCOPT='-O3' thttpd                                      && \
    install -m 755 thttpd /build

ADD ./assets/build/src/dumb-init.c /tmp
RUN gcc -std=gnu99 -static -s -Wall -Werror -O3 -o dumb-init        \
    dumb-init.c                                                  && \
    install -m 755 dumb-init /build

###################################################################

FROM alpine:3.8

MAINTAINER <hakke_007@gmx.de>

LABEL description="thttpd docker container based on alpine"

COPY --from=builder /build/thttpd /usr/sbin/thttpd
COPY --from=builder /build/dumb-init /usr/bin/dumb-init
COPY ./assets/build/etc/thttpd.conf /etc/thttpd/thttpd.conf

RUN addgroup -g 118 www-data
RUN adduser -u 1003 -D -h /var/www -s /sbin/nologin -g thttpd thttpd
RUN addgroup thttpd www-data

EXPOSE 80

ENTRYPOINT [ "dumb-init", "-v", "/usr/sbin/thttpd", "-D", "-C", "/etc/thttpd/thttpd.conf" ]
