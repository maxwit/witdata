#!/bin/sh --login

# FIXME
master=`hostname`

echo -n "validating hadoop on $USER@$master: "

if [ -z "$HADOOP_HOME" ]; then
	echo "not installed"
	exit 1
else
	echo "$HADOOP_HOME"
fi
echo

temp=`mktemp`
date > $temp

echo "putting $temp to master ..."
$HADOOP_HOME/bin/hadoop fs -put $temp / || exit 1
echo

for slave in `cat $HADOOP_HOME/etc/hadoop/slaves`
do
	echo "checking '$slave' ..."
	ssh $slave $HADOOP_HOME/bin/hadoop fs -ls /`basename $temp` || exit 1
done
echo

echo "removing $temp ..."
#ssh $user@$master hadoop-2.7.1/bin/hadoop fs -rm /$temp || exit 1
echo
