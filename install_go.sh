#!/bin/sh
# vim: et smartindent sr sw=4 ts=4:
export GOLANG_VERSION=1.9.2
echo "INFO $0: installing go $GOLANG_VERSION"

docker_gitrepo="https://github.com/docker-library/golang"
tmp_dir=/var/tmp/go-$GOLANG_VERSION
asset_dir=$tmp_dir/1.9/alpine3.6

echo "INFO $0: gathering build requirements"
PKGS="ca-certificates bash git gcc musl-dev openssl go wget"
apk --no-cache add --update $PKGS \
&& export \
    GOROOT_BOOTSTRAP="$(go env GOROOT)" \
    GOOS="$(go env GOOS)" \
    GOARCH="$(go env GOARCH)" \
    GO386="$(go env GO386)" \
    GOARM="$(go env GOARM)" \
    GOHOSTOS="$(go env GOHOSTOS)" \
    GOHOSTARCH="$(go env GOHOSTARCH)" \
&& git clone $docker_gitrepo --depth 1 $tmp_dir \
&& cd $tmp_dir \
&& wget -O go.tgz "https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz" \
&& echo '665f184bf8ac89986cfd5a4460736976f60b57df6b320ad71ad4cef53bb143dc *go.tgz' | sha256sum -c - \
|| exit 1

echo "INFO $0: building go from src"
tar -C /usr/local -xzf go.tgz \
&& rm go.tgz \
&& cd /usr/local/go/src \
&& for i in $asset_dir/*.patch; do echo $i; patch -p2 -i "$i" ; done \
&& ./make.bash || exit 1

echo "INFO $0: putting go-wrapper in PATH"
cp $asset_dir/go-wrapper /usr/local/bin/go-wrapper \
&& chmod a+x /usr/local/bin/go-wrapper

echo "INFO $0: cleaning up tmp assets"
apk --no-cache --update del go
rm -rf $tmp_dir

echo "INFO $0: verifying build"
if ! go version | grep "go$GOLANG_VERSION"
then
    echo "ERROR $0:: ... could not build go $GOLANG_VERSION"
    exit 1
else
    exit 1
fi
