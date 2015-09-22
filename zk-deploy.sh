#!/bin/sh --login

cd `dirname $0`

if [ "$ZOOKEEPER_HOME" != "" ]; then
	echo -e "Hive already installed!\n"
	exit 1
fi

if [ -z "$JAVA_HOME" ]; then
	echo -e "JAVA_HOME not set!\n"
	exit 1
fi

. ./parse-config.sh

echo "extracting $zk ..."
tar xf $repo/${zk}.tar.gz -C $HOME || {
	echo "extract failed!"
	exit 1
}

cd $HOME/$zk

if [ -e /etc/redhat-release ]; then
	sh_config="$HOME/.bashrc"
else
	sh_config="$HOME/.profile"
fi

cat >> $sh_config << EOF
export ZOOKEEPER_HOME=\$HOME/$zk
EOF

cp -v conf/zoo{_sample,}.cfg || exit 1
bin/zkServer.sh start || exit 1
