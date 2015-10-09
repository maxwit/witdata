#!/bin/sh

if [ ! -z "$GIT_BRANCH" ]; then
	BRANCH=`basename $GIT_BRANCH`
else
	BRANCH=`git branch | awk '$1 == "*" {print $2}'`
fi

pusher=`echo $BRANCH | awk -F '-' '{print $2}'`
if [ -n "$pusher" ]; then
	user=`awk -F ':' -v user="$pusher" '{if ($1 == user) {print $1}}' /etc/passwd`
fi

./test.sh --user hadoop || exit 1
if [ -n "$user" ]; then
	./test.sh --user hadoop --master $user-node1.maxwit.com --slaves $pusher-node2.maxwit.com,$pusher-node3.maxwit.com
fi
