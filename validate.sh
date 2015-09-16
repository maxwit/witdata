#!/bin/sh

temp=`mktemp`

echo "testing 'fs -put' ..."
$HOME/hadoop-2.7.1/bin/hadoop fs -put $temp /

for slave in `cat .slaves`
do
	echo "@ '$slave' ..."
	ssh $slave $HOME/hadoop-2.7.1/bin/hadoop fs -ls /`basename $temp`
	ret=$?
	if [ $ret -ne 0 ]; then
		echo "failed."
		exit $ret
	else
		echo "OK."
	fi
done
