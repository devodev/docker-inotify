FROM alpine:3.19.1

RUN apk add -U \
        bash \
        curl \
        inotify-tools \
        netcat-openbsd \
        net-tools \
        wget

COPY scripts/ /
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "inotify-script" ]
