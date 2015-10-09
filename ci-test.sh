#!/bin/sh

if [ ! -z "$GIT_BRANCH" ]; then
	BRANCH=`basename $GIT_BRANCH`
else
	BRANCH=`git branch | awk '$1 == "*" {print $2}'`
fi

pusher=`echo $BRANCH | awk -F '-' '{print $2}'`

if [ -z "$pusher" ]; then
	pusher=$USER
fi

master="$pusher-node1.maxwit.com"
slaves="$pusher-node2.maxwit.com $pusher-node3.maxwit.com"
user="hadoop"
wd=`basename $PWD`

cat > .config << EOF
config_master="$master"
config_slaves="$slaves"

config_hadoop="hadoop-2.7.1"
config_hive="apache-hive-1.2.1-bin"
config_pig="pig-0.15.0"
config_zk="zookeeper-3.4.6"
config_hbase="hbase-1.1.2"
config_spark="spark-1.5.1-bin-hadoop2.6"
EOF

./fast-scp $PWD $user@$master || exit 1

ssh $user@$master << EOF
echo "host: `hostname`"
$wd/mdh destroy || exit 1
EOF

ssh $user@$master << EOF
echo "host: `hostname`"
$wd/mdh deploy || exit 1
EOF
[ $? -ne 0 ] && exit $?

ssh $user@$master << EOF
echo "host: `hostname`"
$wd/mdh start || exit 1
EOF

ssh $user@$master << EOF
echo "host: `hostname`"
$wd/mdh test || exit 1
EOF
