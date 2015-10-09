#!/bin/sh

user=$USER
master='localhost'
slaves=()

while [ $# -gt 0 ]
do
	case $1 in
	-u|--user)
		user=$2
		shift
		;;
	-m|--master)
		master=$2
		shift
		;;
	-s|--slaves)
		slaves=(${2//,/ })
		shift
		;;
	*)
		echo "usage: `basename $0 [-m|--master <host name>] [-s|--slaves <slave list>]`"
		exit 1
	esac

	shift
done

cp -v configs/config-hadoop-2.7 .config || exit 1

if [ ${#slaves[@]} -gt 0 ]; then
	cat >> .config << EOF
config_slaves="${slaves[@]}"
EOF
fi

wd=`basename $PWD`

./fast-scp $PWD $user@$master || exit 1

for cmd in deploy start test stop destroy
do
	ssh $user@$master << EOF
echo "host: `hostname`"
$wd/mdh $cmd || exit 1
EOF
	[ $? -ne 0 ] && exit 1
done
