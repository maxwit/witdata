#!/bin/sh

if [ "$HADOOP_HOME" == "" ]; then
	echo -e "Warning:hadoop do not installed!\n"
	exit 1
fi

if [ "$HIVE_HOME" != "" ]; then
	echo -e "Warning: previous hive already installed!\n"
fi

if [ -z "$JAVA_HOME" ]; then
	echo -e "JAVA_HOME not set!\n"
	exit 1
fi

repo='/mnt/witpub/devel/hadoop/'
hive='apache-hive-1.2.1-bin'
hive_tarball=$hive.tar.gz

cd
echo "extracting $hive ..."
tar xf $repo/$hive_tarball || exit 1

grep HIVE_HOME ~/.bashrc || cat >> ~/.bashrc <<EOF 
export HIVE_HOME=$HOME/$hive
export PATH=\$PATH:\$HIVE_HOME/bin
export HIVE_CONF_DIR=\$HIVE_HOME/conf
EOF
