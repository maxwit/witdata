#!/bin/sh

if [ -z "$GIT_BRANCH" ]; then
	BRANCH=`git branch | awk '$1 == "*" {print $2}'`
else
	BRANCH=`basename $GIT_BRANCH`
fi
pusher=`echo $BRANCH | awk -F '-' '{print $2}'`

if [ -z "$pusher" ]; then
	echo "branch not detected!"
	exit 1
fi

cat > .config << EOF
[hadoop]
master = $pusher-node1.maxwit.com
slaves = $pusher-node2.maxwit.com $pusher-node3.maxwit.com

[hive]

[zookeeper]
EOF

./remote-deploy.sh -u hadoop -m $pusher-node1.maxwit.com || exit 1
