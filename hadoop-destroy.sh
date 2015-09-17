#!/bin/sh --login

master=`hostname`

[ -z "$HADOOP_HOME" ] && exit 0

if [ -d $HADOOP_HOME ]; then
	$HADOOP_HOME/sbin/stop-dfs.sh || exit 1
	$HADOOP_HOME/sbin/stop-yarn.sh || exit 1

	for slave in localhost `cat $HADOOP_HOME/etc/hadoop/slaves`
	do
		echo "removing $HADOOP_HOME @ $slave"
		if [ $slave = 'localhost' ]; then
			ssh_cmd=""
		else
			ssh_cmd="ssh $slave"
		fi
		$ssh_cmd rm -rf $HADOOP_HOME || exit 1
		$ssh_cmd rm -rf /tmp/hadoop-$USER || exit 1
	done
fi

sed -i '/export HADOOP_HOME/d' ~/.profile
