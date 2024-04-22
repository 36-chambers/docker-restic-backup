FROM alpine:latest
RUN apk --no-cache add docker-cli restic apk-cron bash tini restic wget tzdata

COPY entrypoint.sh /entrypoint.sh
COPY run.sh /run.sh
RUN chmod +x /entrypoint.sh /run.sh

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
