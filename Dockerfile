# syntax=docker/dockerfile:1.3

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS builder

SHELL ["/bin/bash", "-c"]

ARG POSTFIX_VERSION

COPY scripts/start-postfix.sh /scripts/
COPY patches /patches
RUN \
    set -E -e -o pipefail \
    && homelab build-pkg-from-std-deb-src "postfix=${POSTFIX_VERSION:?}"

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

SHELL ["/bin/bash", "-c"]

ARG USER_NAME
ARG GROUP_NAME
ARG USER_ID
ARG GROUP_ID
ARG PACKAGES_TO_INSTALL
ARG POSTFIX_VERSION

RUN \
    --mount=type=bind,target=/scripts,from=builder,source=/scripts \
    --mount=type=bind,target=/deb-pkgs,from=builder,source=/deb-pkgs \
    set -E -e -o pipefail \
    # Create the user and the group. \
    && homelab add-user \
        ${USER_NAME:?} \
        ${USER_ID:?} \
        ${GROUP_NAME:?} \
        ${GROUP_ID:?} \
        --create-home-dir \
    # Install dependencies. \
    && homelab install $PACKAGES_TO_INSTALL \
    && ls -l /deb-pkgs/ \
    # Install the postfix .deb files built from the builder stage. \
    && homelab install-deb-pkg \
        postfix_${POSTFIX_VERSION:?} \
        postfix-pcre_${POSTFIX_VERSION:?} \
    # Do not run postfix services in a chroot jail since postfix will \
    # already be within a container. \
    && sed -E -i \
        's/^([^# ]+\s+[^ ]+\s+[^ ]+\s+[^ ]+\s+)([^ ]+)(\s+[^ ]+\s+[^ ]+\s+.*)$/\1n\3/' \
        /etc/postfix/master.cf \
    # Set up the necessary directories along with granting \
    # permissions to the user we created. \
    && chown -R postfix:postfix /etc/postfix/ /var/spool/ /etc/sasldb2 \
    # Copy the start-postfix.sh script. \
    && mkdir -p /opt/postfix/ \
    && cp /scripts/start-postfix.sh /opt/postfix/ \
    && ln -sf /opt/postfix/start-postfix.sh /opt/bin/start-postfix \
    # Clean up. \
    && homelab cleanup

ENV USER=${USER_NAME}
USER ${USER_NAME}:${GROUP_NAME}
WORKDIR /home/${USER_NAME}

CMD ["start-postfix"]
STOPSIGNAL SIGTERM
