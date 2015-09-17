#!/bin/sh

if [ -z "$GIT_BRANCH" ]; then
	BRANCH=`git branch | awk '/^*/ {print $2}'`
else
	BRANCH=`basename $GIT_BRANCH`
fi
pusher=`echo $BRANCH | awk -F '-' '{print $2}'`

cat > .config << EOF
[hadoop]
master = node1.$pusher
slaves = node2.$pusher node3.$pusher

[hive]

[zookeeper]
EOF

./remote-deploy.sh -u hadoop -m node1.$pusher || exit 1
