FROM docker:dind

RUN apk add --no-cache --update \
    aws-cli \
    bash \
    coreutils \
    curl \
    docker-compose \
    git \
    jq \
    nodejs \
    npm \
    openjdk11 \
    unzip

# Download and install Nix and install
ARG NIX_VERSION=2.3.14
RUN wget https://nixos.org/releases/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}-$(uname -m)-linux.tar.xz \
    && tar xf nix-${NIX_VERSION}-$(uname -m)-linux.tar.xz \
    && addgroup -g 30000 -S nixbld \
    && for i in $(seq 1 30); do adduser -S -D -h /var/empty -g "Nix build user $i" -u $((30000 + i)) -G nixbld nixbld$i ; done \
    && mkdir -m 0755 /etc/nix \
    && echo 'sandbox = false' > /etc/nix/nix.conf \
    && mkdir -m 0755 /nix && USER=root sh nix-${NIX_VERSION}-$(uname -m)-linux/install \
    && ln -s /nix/var/nix/profiles/default/etc/profile.d/nix.sh /etc/profile.d/ \
    && rm -r /nix-${NIX_VERSION}-$(uname -m)-linux* \
    && rm -rf /var/cache/apk/* \
    && /nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-old \
    && /nix/var/nix/profiles/default/bin/nix-store --optimise \
    && /nix/var/nix/profiles/default/bin/nix-store --verify --check-contents

# Download and install babashka
ARG BABASHKA_VERSION="1.0.165"
RUN curl -sLO https://github.com/babashka/babashka/releases/download/v${BABASHKA_VERSION}/babashka-${BABASHKA_VERSION}-linux-amd64-static.tar.gz \
    && tar -xzf babashka-${BABASHKA_VERSION}-linux-amd64-static.tar.gz \
    && mv bb /usr/local/bin \
    && rm babashka-${BABASHKA_VERSION}-linux-amd64-static.tar.gz

# Download and install Clojure tools
ARG CLOJURE_TOOLS_VERSION="1.11.1.1189"
RUN curl -O https://download.clojure.org/install/linux-install-${CLOJURE_TOOLS_VERSION}.sh \
    && chmod +x linux-install-${CLOJURE_TOOLS_VERSION}.sh \
    && ./linux-install-${CLOJURE_TOOLS_VERSION}.sh \
    && rm linux-install-${CLOJURE_TOOLS_VERSION}.sh \
    && clojure -P

# Download and install clj-kondo
ARG CLJ_KONDO_VERSION="2022.11.02"
RUN curl -sLO https://github.com/clj-kondo/clj-kondo/releases/download/v${CLJ_KONDO_VERSION}/clj-kondo-${CLJ_KONDO_VERSION}-linux-static-amd64.zip \
    && unzip clj-kondo-${CLJ_KONDO_VERSION}-linux-static-amd64.zip \
    && rm clj-kondo-${CLJ_KONDO_VERSION}-linux-static-amd64.zip \
    && mv clj-kondo /usr/local/bin

ENV \
    ENV=/etc/profile \
    USER=root \
    PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NIX_PATH=/nix/var/nix/profiles/per-user/root/channels

ADD already-succeeded \
    ghcr-login \
    record-success \
    skip-ci \
    start-docker \
    voom-like-version \
    /usr/local/bin/
