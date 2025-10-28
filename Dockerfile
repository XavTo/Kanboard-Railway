FROM kanboard/kanboard:v1.2.48

RUN apk add --no-cache inotify-tools

COPY docker-start.sh /usr/local/bin/docker-start.sh
RUN chmod +x /usr/local/bin/docker-start.sh

ENTRYPOINT ["/usr/local/bin/docker-start.sh"]
