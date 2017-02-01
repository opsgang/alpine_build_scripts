#!/bin/sh
# vim: et smartindent sr sw=4 ts=4:
APK_TMP=/var/cache/apk
GET_PIP=https://bootstrap.pypa.io/get-pip.py
BUILD_PKGS="wget make python-dev alpine-sdk libffi-dev openssl-dev"
PKGS="$BUILD_PKGS curl python less"
echo "INFO $0: installing python, pip and credstash"
apk --no-cache add --update $PKGS                  \
&& wget -q -T 10 -O /var/tmp/get-pip.py $GET_PIP   \
&& python /var/tmp/get-pip.py                      \
&& pip --no-cache-dir install --upgrade credstash  \
&& apk --no-cache --purge del --update $BUILD_PKGS \
&& rm -rf /var/tmp/get-pip.py $APK_TMP/*           \
&& credstash -h >/dev/null 2>&1                    \
&& echo "INFO $0: credstash installed successfully"
