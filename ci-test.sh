#!/bin/sh

if [ -z "$GIT_BRANCH" ]; then
	BRANCH=`git branch | awk '/^*/ {print $2}'`
else
	BRANCH=`basename $GIT_BRANCH`
fi
pusher=`echo $BRANCH | awk -F '-' '{print $2}'`

cat > .config << EOF
master = node1.$pusher
slaves = node2.$pusher node3.$pusher
user = hadoop
EOF

./remote-deploy.sh || exit 1

./validate.sh || exit 1
