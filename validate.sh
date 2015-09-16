#!/bin/sh

. ./parse-config.sh

if [ -z "$user" ]; then
	user=hadoop
fi

temp=`ssh $master mktemp`
ssh $user@$master hadoop-2.7.1/bin/hadoop fs -put $temp /

for slave in ${slaves[@]}
do
	echo "@ '$slave' ..."
	ssh $user@$slave hadoop-2.7.1/bin/hadoop fs -ls /`basename $temp`
	ret=$?
	if [ $ret -ne 0 ]; then
		echo "Failed."
		exit $ret
	else
		echo "OK."
	fi
done
