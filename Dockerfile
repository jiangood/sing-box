# sing-box core, pinned to the version below. Update it here only.
FROM ghcr.io/sagernet/sing-box:v1.14.4 AS singbox

# Add a small shell/OpenSSL layer so first boot can create a secure config.
FROM alpine:3.22
RUN apk add --no-cache ca-certificates openssl \
    && mkdir -p /etc/sing-box /var/lib/sing-box
COPY --from=singbox /usr/local/bin/sing-box /usr/local/bin/sing-box
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh

WORKDIR /etc/sing-box
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
