#!/bin/sh

destroy=0

while [ $# -gt 0 ]
do
	case $1 in
	-d)
		destroy=1
		;;
	*)
		echo "usage: `basename $0 [-d]`"
		exit 1
	esac
done

cd `dirname $0`
top=$PWD

if [ -z "$JAVA_HOME" ]; then
	echo -e "JAVA_HOME not set!\n"
	exit 1
fi

. ./parse-config.sh

function execute
{
	func=$1
	echo "#########################################"
	echo "  executing $func() ..."
	echo "#########################################"
	$func
	echo
}

for app in hadoop zk
do
	if [ ! -e ./$app.sh ]; then
		echo "$app.sh does not exists!"
		exit 1
	fi

	. $TOP/$app.sh

	cd $TOP

	if [ $destroy -eq 0 ]; then
		execute ${app}_deploy || exit 1
		execute ${app}_validate || exit 1
	else
		execute ${app}_destroy || exit 1
	fi
	echo
done
