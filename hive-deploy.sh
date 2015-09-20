#!/bin/sh

if [ "$HADOOP_HOME" == "" ]; then
	echo -e "Warning:hadoop do not installed!\n"
	exit 1
fi

if [ "$HIVE_HOME" != "" ]; then
	echo -e "Hive already installed!\n"
	exit 1
fi

if [ -z "$JAVA_HOME" ]; then
	echo -e "JAVA_HOME not set!\n"
	exit 1
fi

. ./parse-config.sh

echo "extracting $hive ..."
tar xf $repo/${hive}.tar.gz -C $HOME || exit 1

if [ -e /etc/redhat-release ]; then
	sh_config="$HOME/.bashrc"
else
	sh_config="$HOME/.profile"
fi

cat >> $sh_config << EOF
export HIVE_HOME=\$HOME/$hive
export HIVE_CONF_DIR=\$HIVE_HOME/conf
export PATH=\$PATH:\$HIVE_HOME/bin
EOF
