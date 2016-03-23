#!/bin/bash
# Creates an Ansible inventory from `fuel node`
#
# fsoppelsa@mirantis.com

NAME="create-inventory.sh"
ROLES="controller compute ceph-osd"
ENV=""
FILE="inventory"

usage() {
    echo "Usage: ./$NAME [-e ENV] [-f OUTFILE] [-h]"
    echo "	-e: specify the environment (default: ALL)"
    echo "	-f: specify an output file (default: inventory)"
    echo "	-h: show this help"
}

parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# Handle the initial | in `fuel node` command in old releases
fuel_version() {
	for conf in "/etc/fuel/version.yaml"
	do
		eval $(parse_yaml $conf "fuel_")
	done
	if [ $fuel_VERSION_release == "8.0" -o \
	     $fuel_VERSION_release == "7.0" -o \
	     $fuel_VERSION_release == "6.1" ]
	then
		AWKOPT="10"
	else
		AWKOPT="9"
	fi
}

make_inventory() {
	> $FILE
	for role in $ROLES
	do 
	    echo "[$role]" >> $FILE && fuel node $ENVOPT | grep $role | awk "{print \$${AWKOPT}}" >> $FILE;
	done
}

while getopts e:f:h option
do
	case "$option"
	in
	e) ENV=$OPTARG;;
        f) FILE=$OPTARG;;
        h) usage
           exit 0;;
       \?) usage
           exit 0;;
esac
done

ENVOPT=""
if [ "$ENV" != "" ]
then
    ENVOPT="--env $ENV"
fi

fuel_version
make_inventory
