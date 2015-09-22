#!/bin/sh --login

cd `dirname $0`

if [ -z "$ZOOKEEPER_HOME" ]; then
	echo "not installed"
	exit 1
else
	echo "$ZOOKEEPER_HOME"
fi
echo

. ./parse-config.sh

cd $ZOOKEEPER_HOME || exit 1

pwd
ls
ls bin/
bin/zkCli.sh -server 127.0.0.1:2181 << EOF
ls /
EOF

exit $?