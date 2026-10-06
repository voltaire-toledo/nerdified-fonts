# The upstream image supplies a FontForge build maintained for the Nerd Fonts
# patcher. Its 4.x tag is the patcher program version, not the Nerd Fonts
# release version used to name this repository's ZIPs.
FROM nerdfonts/patcher:4.26.0

# The repository's wrapper needs Bash, the release downloader needs curl and
# unzip, and metadata normalization and validation need fontTools.
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/latest-stable/community \
    bash curl unzip py3-fonttools

WORKDIR /workspace
ENTRYPOINT ["/bin/bash", "/workspace/scripts/patch_fonts_container.sh"]
