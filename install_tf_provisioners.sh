#!/bin/bash
# vim: et smartindent sr sw=4 ts=4:
# For versions of terraform >= 0.10, the provisioner has to be installed
# separately.
#
VERSIONS_FILE=/provisioner.versions
PROVISIONERS_DIR=/tf_provisioners

rm -rf $PROVISIONERS_DIR ; mkdir -p $PROVISIONERS_DIR

need_provisioners() {
    # only interested if version more than or equal to 0.10.0
    local valid="0.10.0" tv=""
    tv=$(terraform --version | grep -Po '(?<=Terraform v)[\d\.]+')
    if [[ $? -ne 0 ]] || [[ -z "$tv" ]]; then
        echo "ERROR $0: could not determine terraform version from terraform --version" >&2
        exit 1 # deliberately short-circuit, as return val used for truth
    fi

    # list versions in ascending order and ensure our current version not first listed.
    if [[ $(echo -e "$tv\n$valid" | sort -V | head -n 1) == "$tv" ]]; then
        echo "WARN $0: getting provisioners only needed with terraform versions >= $valid" >&2
        echo "WARN $0: ... currently using terraform version $tv" >&2
        return 1
    else
        return 0
    fi

}

tf_provisioner_code() {
    local pn="$1" # provisioner name clause
    local pv="$2" # provisioner version clause

    if [[ -z "$pv" ]]; then
        echo "ERROR $0: tf_provisioner_code(): must pass provisioner name and version" >&2
        return 1
    fi

    cat << EOF
provider "$pn" {
	version = "$pv"
}
EOF
}

tf_main_tf() {
	local f="" pn="" pv="" 
	while IFS= read -r line ; do
		pn=$(echo $line | grep -Po '^[^=]+' | sed -e 's/^ *//' -e 's/ $//')
		pv=$(
			echo $line \
			| grep -Po '(?<==)[^=]+' \
			| sed -e 's/"//g' -e "s/'//g" -e 's/^ *//' -e 's/ $//'
		)
		f="$f$(tf_provisioner_code "$pn" "$pv")"
	done < <(cat $VERSIONS_FILE | grep -v '^#')
	echo "$f"
}

echo "INFO $0: ... checking we need to get provisioners (if terraform >= 0.10.x)"
need_provisioners || exit 0 # exit-on-runtime-err within func

if [[ ! -r $VERSIONS_FILE ]]; then
    echo "ERROR $0: ... $VERSIONS_FILE not readable" >&2
    exit 1
fi

echo "INFO $0: ... generating main.tf to download provisioners"
f=$(tf_main_ft)

(
    cd /tf_provisioners
    echo "$f">main.tf
    terraform init || exit 1
) || exit 1

