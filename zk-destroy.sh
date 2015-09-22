#!/bin/sh --login

cd `dirname $0`

[ -z "$ZOOKEEPER_HOME" ] && exit 0

zk=`basename $ZOOKEEPER_HOME`
echo "stoping $zk ..."
cd $ZOOKEEPER_HOME
bin/zkServer.sh stop || exit 1

echo "removing $zk ..."
if [ -d $ZOOKEEPER_HOME ]; then
	rm -rf $ZOOKEEPER_HOME || exit 1
fi

if [ -e /etc/redhat-release ]; then
	sh_config="$HOME/.bashrc"
else
	sh_config="$HOME/.profile"
fi

sed -i '/ZOOKEEPER_HOME/d' $sh_config

echo "Done."
