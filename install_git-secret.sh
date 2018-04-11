#!/bin/sh
# vim: et smartindent sr sw=4 ts=4:
echo "INFO $0: cloning git-secret"
if [[ -z $(command -v make) ]]; then
  BUILD_PKGS="make"
fi

PKGS="$BUILD_PKGS git bash gawk gnupg"
apk --no-cache --update add $PKGS

git clone -q https://github.com/sobolevn/git-secret.git \
&& cd git-secret \
&& git remote rm origin \
&& make \
&& make install \
&& rm -rf git-secret \
&& if [[ ! -z $BUILD_PKGS ]]; then apk --no-cache --purge del $BUILD_PKGS; fi \
&& rm -rf /var/cache/apk/* \
&& echo "INFO $0: git-secret installed successfully"

exit 0
