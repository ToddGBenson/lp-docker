FROM alpine:3.13.0

ARG BUILD_DATE
ARG VCS_REF
ARG BUILD_VERSION

LABEL MAINTAINER="Todd Benson"
LABEL org.opencontainers.schema-version="1.0"
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.title="Hugo-Builder"
LABEL org.opencontainers.image.description="Ballerina language runtime"
LABEL org.opencontainers.image.url="http://github.com/toddgbenson"
LABEL org.opencontainers.image.vcs-url="https://github.com/toddgbenson/container-support"
LABEL org.opencontainers.image.revision=$VCS_REF
LABEL org.opencontainers.image.version=$BUILD_VERSION


SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN apk add --no-cache \
    curl \
    git \
    openssh-client \
    rsync

ENV VERSION 0.64.0

WORKDIR /usr/local/src

RUN curl -L -o hugo_${VERSION}_Linux-64bit.tar.gz https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_${VERSION}_Linux-64bit.tar.gz \
     && curl -L https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_${VERSION}_checksums.txt | grep hugo_${VERSION}_Linux-64bit.tar.gz | sha256sum -c \
     && tar -xf hugo_${VERSION}_Linux-64bit.tar.gz \
     && rm hugo_${VERSION}_Linux-64bit.tar.gz \
     && mv hugo /usr/local/bin/hugo

RUN addgroup -Sg 1000 hugo \
    && adduser -SG hugo -u 1000 -h /src hugo

WORKDIR /src
USER hugo
EXPOSE 1313
HEALTHCHECK --interval=10s --timeout=10s --start-period=15s \
  CMD hugo env || exit 1
