#!/bin/sh
# vim: et smartindent sr sw=4 ts=4:
#
# ... most of the packages here provide GNU versions of commonly used shell functions.
# The default alpine ones (being from the minimal busybox binary) are
# as sub-functional as those provided by BSD)
#
# We install additionally other tools ubiquitous in our delivery pipeline.
# e.g. gettext is installed to provide envsubst
#      coreutils provides a sort with the --version-sort option.
#      GNU sed handles a wider range of regexs.
APK_TMP=/var/cache/apk
PKGS="
    bash
    bind-tools
    ca-certificates
    coreutils
    curl
    gettext
    git
    grep
    jq
    make
    openssh-client
    sed
    tree
    wget
"
echo "INFO $0: installing" $PKGS

apk --no-cache add --update $PKGS \
&& rm -rf $APK_TMP/*
