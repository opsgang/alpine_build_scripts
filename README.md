# alpine\_build\_scripts

_... ash scripts to install common tools on alpine_

## What?

Self contained scripts that should run under the default sh on Alpine, ash.

Each script is intended to install _something_ taking up very little disk.

Generally we use alpine within a docker container. So we apologise if the scripts
look very much a long stream of ANDed dockerfile-run directives.

## Contributing

We take pull requests seriously ;)

Each script should cleanup (i.e. remove) any **new** packages installed.

Equally, don't remove any package that was already installed before the
script ran.

>
> E.g.
> You might install wget to download terraform. However your installation script for
> for terraform should remove it before completion as wget is not required
> for terraform to run correctly.
>

## Why?

Alpine is tiny. Seems a shame to bloat it up unnecessarily with lazy
installs of other software.

## How?

The scripts generally delete all unneeded files and avoid file-system caches
for package managers etc.

## ... Docker

For creating containers using alpine as a base, these scripts
will do stuff without polluting your Dockerfile or equivalent
with lots of commands.

This keeps your Dockerfile readable but also allows for more complex logic during the
build process inside your scripts without the creation of disk-consuming additional
image layers.

### Example - build image foo with awscli and 'essentials'

        cd /my/dir/with/Dockerfile
        git clone https://github.com/opsgang/alpine_build_scripts.git

```dockerfile
        FROM gliderlabs/alpine:3.3
        MAINTAINER jinal--shah <jnshah@gmail.com>
        LABEL Name="foo" Vendor="sortuniq" Version="0.0.1" Description="build foo"

        ENV SCRIPT_DIR_LOCAL="alpine_build_scripts" \
            SCRIPT_DIR="/var/tmp/scripts"

        COPY $SCRIPT_DIR_LOCAL $SCRIPT_DIR/

        RUN chmod a+x $SCRIPT_DIR/*                        \
            && $SCRIPT_DIR/install_awscli.sh               \
            && $SCRIPT_DIR/install_essentials.sh           \
            && rm -rf /var/cache/apk/* $SCRIPT_DIR

        CMD ["/usr/bin/make", "-C", "my_project", "build"]
```

