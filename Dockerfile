FROM alpine:3.22.4

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
