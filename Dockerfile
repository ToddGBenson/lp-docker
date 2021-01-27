FROM alpine:3.13.0


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

HEALTHCHECK --timeout=3s CMD hugo env || exit 1

WORKDIR /src

EXPOSE 1313
