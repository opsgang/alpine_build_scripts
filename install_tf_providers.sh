#!/bin/bash
# vim: et smartindent sr sw=4 ts=4:
# For versions of terraform >= 0.10, the provider has to be installed
# separately.
#
PREINSTALLED_PLUGINS=${PREINSTALLED_PLUGINS:-/tf_providers}
PROVIDER_VERSIONS=${PROVIDER_VERSIONS:-/provider.versions}

need_providers() {
    # only interested if version more than or equal to 0.10.0
    local valid="0.10.0" tv=""
    tv=$(terraform --version | grep -Po '(?<=Terraform v)[\d\.]+')
    if [[ $? -ne 0 ]] || [[ -z "$tv" ]]; then
        echo "ERROR $0: could not determine terraform version from terraform --version" >&2
        exit 1 # deliberately short-circuit, as return val used for truth
    fi

    # list versions in ascending order and ensure our current version not first listed.
    if [[ $(echo -e "$tv\n$valid" | sort -V | head -n 1) == "$tv" ]]; then
        echo "WARN $0: getting providers only needed with terraform versions >= $valid" >&2
        echo "WARN $0: ... currently using terraform version $tv" >&2
        return 1
    else
        return 0
    fi

}

tf_provider_code() {
    local pn="$1" # provider name clause
    local pv="$2" # provider version clause

    if [[ -z "$pv" ]]; then
        echo "ERROR $0: tf_provider_code(): must pass provider name and version" >&2
        return 1
    fi

    cat << EOF
provider "$pn" {
    version = "$pv"
}
EOF
}

tf_main() {
    local f="" pn="" pv=""
    while IFS= read -r line ; do
        pn=$(echo $line | grep -Po '^[^=]+' | sed -e 's/^ *//' -e 's/ $//')
        pv=$(
            echo $line \
            | grep -Po '(?<==)[^=]+' \
            | sed -e 's/"//g' -e "s/'//g" -e 's/^ *//' -e 's/ $//'
        )
        f="$f$(tf_provider_code "$pn" "$pv")"
    done < <(cat $PROVIDER_VERSIONS | grep -v '^#')
    echo "$f"
}

echo "INFO $0: ... checking we need to get providers (if terraform >= 0.10.x)"
need_providers || exit 0 # exit-on-runtime-err within func

rm -rf $PREINSTALLED_PLUGINS ; mkdir -p $PREINSTALLED_PLUGINS

if [[ ! -r $PROVIDER_VERSIONS ]]; then
    echo "ERROR $0: ... $PROVIDER_VERSIONS not readable" >&2
    exit 1
fi

echo "INFO $0: ... generating main.tf to download providers"
f=$(tf_main)

(
    cd $PREINSTALLED_PLUGINS
    echo "$f">main.tf
    terraform init || exit 1
    rm main.tf
    find . -name '*.tfstate' -exec rm {} \; || true
) || exit 1

