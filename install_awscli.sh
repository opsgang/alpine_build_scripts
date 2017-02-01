#!/bin/sh
# vim: et smartindent sr sw=4 ts=4:
APK_TMP=/var/cache/apk
GET_PIP=https://bootstrap.pypa.io/get-pip.py
BUILD_PKGS="openssl-dev wget python-dev ca-certificates"
PKGS="$BUILD_PKGS python groff less"
echo "INFO $0: installing python, pip and awscli"
apk --no-cache add --update $PKGS                  \
&& wget -q -T 10 -O /var/tmp/get-pip.py $GET_PIP   \
&& python /var/tmp/get-pip.py                      \
&& pip --no-cache-dir install --upgrade awscli     \
&& apk --no-cache --purge del --update $BUILD_PKGS \
&& rm -rf /var/tmp/get-pip.py $APK_TMP/*           \
&& aws --version                                   \
&& echo "INFO $0: aws version $(aws --version) installed successfully"
