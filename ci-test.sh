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

cat > .config << EOF
config_user="$user"
config_master="$master"
config_slaves="$slaves"

#config_hadoop="hadoop-2.7.1"
#config_hive="apache-hive-1.2.1-bin"
config_zk="zookeeper-3.4.6"
config_hbase="hbase-1.1.2"
EOF

wd=`basename $PWD`

./fast-scp $PWD $user@$master || exit 1

ssh $user@$master << EOF
$wd/deploy-all.sh -d || exit 1
EOF
echo

ssh $user@$master << EOF
$wd/deploy-all.sh || exit 1
EOF
exit $?
