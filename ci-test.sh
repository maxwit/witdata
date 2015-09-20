#!/bin/sh

if [ -z "$GIT_BRANCH" ]; then
	BRANCH=`git branch | awk '/^*/ {print $2}'`
else
	BRANCH=`basename $GIT_BRANCH`
fi
pusher=`echo $BRANCH | awk -F '-' '{print $2}'`

cat > .config << EOF
[hadoop]
master = $push-node1.maxwit.com
slaves = $push-node2.maxwit.com $push-node3.maxwit.com

[hive]

[zookeeper]
EOF

./remote-deploy.sh -u hadoop -m $push-node1.maxwit.com || exit 1
