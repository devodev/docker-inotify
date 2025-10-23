FROM alpine:3.21.3

RUN apk add -U \
        bash \
        curl \
        inotify-tools \
        netcat-openbsd \
        net-tools \
        tini \
        wget

COPY scripts/ /
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT [ "/sbin/tini", "-v", "--", "/docker-entrypoint.sh" ]
CMD [ "inotify-script" ]
