#!/bin/sh
# vim: et smartindent sr sw=4 ts=4:
#
# Install version of terraform.
# Allows multiple terraform versions
# under /usr/local/bin
#
# /usr/local/bin/terraform symlink to desired one.
#
# Also installs vim plugin if pathogen detected.
#
VER=${1:-$TERRAFORM_VERSION}
BIN="/usr/local/bin"
ZIP="$BIN/terraform-$VER.zip"

APK_TMP="/var/cache/apk"

if [[ -z "$VER" ]]; then
    echo "ERROR $0: you must supply a version of terraform to use"
    exit 1
fi

if [[ -f $BIN/terraform ]]; then
    if [[ -L $BIN/terraform ]]; then
        if ! rm $BIN/terraform
        then
            echo "ERROR $0: ... could not delete symlink $BIN/terraform"
            exit 1
        fi
    elif [[ -x $BIN/terraform ]]; then
        OLDVER=$($BIN/terraform --version | grep '^Terraform v' | sed -e 's/.* v\(.*\)$/\1/')
        if ! mv $BIN/terraform $BIN/terraform-$OLDVER
        then
            echo "ERROR $0: ... could not move existing to $BIN/terraform-$OLDVER"
            exit 1
        fi
    else
        echo "ERROR $0: ... $BIN/terraform is not a bin or symlink to bin"
        exit 1
    fi
fi

if [[ ! -x $BIN/terraform-$VER ]]; then
    BASE_URI="https://releases.hashicorp.com/terraform"
    DOWNLOAD_URI="$BASE_URI/$VER/terraform_${VER}_linux_amd64.zip"

    REQ_PKGS="wget unzip ca-certificates"
    for p in $REQ_PKGS; do
        if ! apk info | grep "^${p}$" >/dev/null 2>&1
        then
            BUILD_PKGS="$BUILD_PKGS $p"
        fi
    done

    if [[ ! -z $(echo "$BUILD_PKGS" | sed -e 's/ //g') ]] ; then
        echo "INFO $0: installing helper pkgs"
        apk --no-cache add --update $BUILD_PKGS
    fi

    echo "INFO $0: ... downloading terraform $VER"
    wget -q -T 60 -O $ZIP $DOWNLOAD_URI
    if ! unzip -p $ZIP | cat >$BIN/terraform-$VER
    then
        echo "ERROR $0: could not extract terraform from zip"
        exit 1
    fi
    chmod a+x $BIN/terraform-$VER
    rm -f $ZIP
else
    echo "INFO $0: ... $BIN/terraform-$VER available ."
fi

echo "INFO $0: ... pointing $BIN/terraform to $VER"
if ! ln -s $BIN/terraform-$VER $BIN/terraform
then
    echo "ERROR $0: could not repoint $BIN/terraform"
    exit 1
fi

if terraform --version | grep "v${VER}$" 2>/dev/null
then
    echo "INFO $0: installed terraform $VER successfully"
else
    echo "INFO $0: failed to install"
    exit 1
fi

# ... install vim plugin if appropriate
if [[ -w /etc/vim/bundle ]] && [[ ! -d /etc/vim/bundle/vim-terraform ]]; then
    echo "INFO $0: installing vim terraform plugin"
    if ! apk info | grep '^git$' >/dev/null 2>&1
    then
        BUILD_PKGS="$BUILD_PKGS git"
        apk --no-cache add --update git
    fi
    (
        /etc/vim/bundle/vim-terraform >/dev/null 2>&1
        cd /etc/vim/bundle
        git clone https://github.com/hashivim/vim-terraform.git
        rm -rf vim-terraform/.git
    )
fi

if [[ ! -z $(echo "$BUILD_PKGS" | sed -e 's/ //g') ]] ; then
    echo "INFO $0: deleting helper pkgs"
    apk --no-cache --purge del $BUILD_PKGS
fi

rm -rf $APK_TMP/* >/dev/null 2>&1

exit 0
