#!/bin/sh --login

[ -z "$HADOOP_HOME" ] && exit 0

if [ -d $HADOOP_HOME ]; then
	$HADOOP_HOME/sbin/stop-dfs.sh || exit 1
	$HADOOP_HOME/sbin/stop-yarn.sh || exit 1
fi

rm -rf $HADOOP_HOME || exit 1
