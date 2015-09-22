#!/bin/sh

if [ -z "$GIT_BRANCH" ]; then
	BRANCH=`git branch | awk '$1 == "*" {print $2}'`
else
	BRANCH=`basename $GIT_BRANCH`
fi
pusher=`echo $BRANCH | awk -F '-' '{print $2}'`

if [ ! -z "$pusher" ]; then
	master="$pusher-node1.maxwit.com"
	slaves="$pusher-node2.maxwit.com $pusher-node3.maxwit.com"
else
	# FIXME
	master=`hostname`
	slaves="${master//1/2} ${master//1/3}"
fi

cat > .config << EOF
[hadoop]
master = $master
slaves = $slaves

[hive]

[zookeeper]
EOF

user=hadoop
wd=`basename $PWD`

./tar-and-scp $PWD $user@$master

ssh $user@$master $wd/deploy-all.sh || exit 1

ssh $user@$master rm -rf $wd
