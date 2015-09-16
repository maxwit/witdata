#!/bin/sh

. ./parse-config.sh

temp=`ssh $user@$master mktemp`

echo "putting $temp to $user@$master ..."
ssh $user@$master hadoop-2.7.1/bin/hadoop fs -put $temp / || exit 1

for slave in ${slaves[@]}
do
	echo "checking '$slave' ..."
	ssh $user@$slave hadoop-2.7.1/bin/hadoop fs -ls /`basename $temp` || exit 1
#	ret=$?
#	if [ $ret -ne 0 ]; then
#		echo "Failed."
#		exit $ret
#	else
#		echo "OK."
#	fi
done
