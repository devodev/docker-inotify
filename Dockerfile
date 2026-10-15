FROM alpine:3.24.2

RUN apk add -U \
        bash \
        curl \
        inotify-tools \
        netcat-openbsd \
        net-tools \
        tini \
        wget \
    && apk upgrade -U \
        zlib

COPY scripts/ /
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT [ "/sbin/tini", "-v", "--", "/docker-entrypoint.sh" ]
CMD [ "inotify-script" ]
