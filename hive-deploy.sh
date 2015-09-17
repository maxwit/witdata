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

. ./parse-config.sh

echo "extracting $hive ..."
tar xf $repo/${hive}.tar.gz -C $HOME || exit 1

# FIXME
sed -i '/HIVE_/d' ~/.bashrc

cat >> ~/.bashrc << EOF
export HIVE_HOME=\$HOME/$hive
export PATH=\$PATH:\$HIVE_HOME/bin
export HIVE_CONF_DIR=\$HIVE_HOME/conf
EOF
