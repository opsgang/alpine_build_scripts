#!/bin/bash
# vim: et smartindent sr sw=4 ts=4:
# ... get binaries from official docker image ...
#
VER="${1:-1.10}"
IMG="golang:$VER-alpine3.7"
_C="golang-$VER-$(date '+%Y%m%d%H%M%S')"

LDIR=/usr/local/go/$VER
TDIR=/var/tmp/go/$VER

echo "INFO: ... installing go $VER"
echo "INFO: ... creating required dirs"
mkdir -p $LDIR $TDIR || exit 1

if ! apk info | grep '^docker$' >/dev/null
then
    cat <<EOF
WARNING: This script will only work if your current env
WARNING: is capable of running a docker daemon.
WARNING: ... for example, if running this with in another
WARNING: docker container, you may need to have started it
WARNING: with the --privileged option.
WARNING:
WARNING: Alternatively mount the docker.sock from the host
WARNING: and make sure the docker user can access that
WARNING: file in the container.
EOF

    BUILD_PKGS="docker"
    apk --no-cache --update add docker || exit 1
    if [[ ! -e /var/run/docker.sock ]]; then
        dockerd &
    fi
    rc=1
    retries=5
    delay=3
    while [[ $(( retries-- )) -gt 0 ]]; do
        docker images >/dev/null && rc=0 && break
        sleep $delay
    done
    [[ $rc -ne 0 ]] && echo "ERROR: could not bring up dockerd ..." && exit 1
fi

docker pull $IMG || exit 1

echo "INFO: starting up container of $IMG from which we will copy the binaries"
docker run --name $_C --rm $IMG /bin/sh -c "while true ; do sleep 10; done" &
rc=1
retries=5
delay=3
while [[ $(( retries-- )) -gt 0 ]]; do
    docker ps | grep "Up.*$_C" >/dev/null && rc=0 && break
    sleep $delay
done

[[ $rc -ne 0 ]] && echo "ERROR: could not bring up golang container ..." && exit 1

echo "INFO: copying from $_C:/usr/local/go/bin to $TDIR"
docker ps -a
docker cp $_C:/usr/local/go/bin $TDIR
echo "INFO: copying from $TDIR to $LDIR"
cp -a $TDIR/bin $LDIR
rm -rf $TDIR

docker rm -f $_C

echo "INFO: installed - " $(find $LDIR -type f)

if [[ ! -z "$BUILD_PKGS" ]]; then
    pkill -9 dockerd
    apk --no-cache --update del $BUILD_PKGS
fi

(
  export GOBIN=$LDIR/bin
  export LGOBIN=$GOBIN
  export PATH=$GOBIN
  go version || exit 1
) || exit 1

exit 0
