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

cat > .config << EOF
[hadoop]
master = $master
slaves = $slaves

[hive]

[zookeeper]
EOF

user=hadoop
wd=`basename $PWD`

./tar-and-scp $PWD $user@$master || exit 1

ssh $user@$master << EOF
$wd/deploy-all.sh -d || exit 1
EOF

ssh $user@$master << EOF
$wd/deploy-all.sh || exit 1
EOF
exit $?
