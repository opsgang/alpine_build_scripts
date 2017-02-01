#!/bin/sh
# vim: et smartindent sr sw=4 ts=4:
#
VER=${TERRAFORM_VERSION}
if [[ -z "$VER" ]]; then
    echo "ERROR $0: you must supply \$TERRAFORM_VERSION to build"
    exit 1
fi
BIN_DIR="/usr/local/bin"
ZIP="$BIN_DIR/terraform.zip" 
BASE_URI="https://releases.hashicorp.com/terraform"
DOWNLOAD_URI="$BASE_URI/$VER/terraform_${VER}_linux_amd64.zip"
BUILD_PKGS="wget ca-certificates"
APK_TMP="/var/cache/apk"

apk --no-cache add --update $BUILD_PKGS

echo "INFO $0: ... downloading: terraform $VER"
wget -q -T 60 -O $ZIP $DOWNLOAD_URI
unzip $ZIP -d $BIN_DIR

if terraform --version | grep $VER 2>/dev/null
then
    echo "INFO $0: installed terraform $VER successfully"
else
    echo "INFO $0: failed to install"
    exit 1
fi

# ... install vim plugin if needed
if [[ -w /etc/vim/bundle ]]; then
    echo "INFO $0: installing vim terraform plugin"
    apk --no-cache add --update git
    BUILD_PKGS="$BUILD_PKGS git"
    (
        cd /etc/vim/bundle
        git clone https://github.com/hashivim/vim-terraform.git
        rm -rf vim-terraform/.git
    )
fi

apk --no-cache --purge del $BUILD_PKGS
rm -rf $ZIP $APK_TMP/*

exit 0
