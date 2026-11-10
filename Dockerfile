# Keep this version aligned with .github/workflows/docker-publish.yml.
ARG SING_BOX_VERSION=v1.14.4
FROM ghcr.io/sagernet/sing-box:${SING_BOX_VERSION}

WORKDIR /etc/sing-box

# The upstream image provides the official sing-box binary.
ENTRYPOINT ["sing-box"]
CMD ["-D", "/var/lib/sing-box", "-C", "/etc/sing-box", "run", "-c", "/etc/sing-box/config.json"]
