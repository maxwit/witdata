#!/bin/sh

. ./parse-config.sh

echo "validating '$HADOOP' ..."
echo "user = $user"
echo "master = $master"
echo "slaves = ${slaves[@]}"
echo

temp=`ssh $user@$master mktemp`

echo "putting $temp to master ($user@$master) ..."
ssh $user@$master hadoop-2.7.1/bin/hadoop fs -put $temp / || exit 1

for slave in ${slaves[@]}
do
	echo "checking '$slave' ..."
	ssh $user@$slave hadoop-2.7.1/bin/hadoop fs -ls /`basename $temp` || exit 1
done
echo

echo "removing $temp ..."
#ssh $user@$master hadoop-2.7.1/bin/hadoop fs -rm /$temp || exit 1
echo
