./test.sh --user hadoop || exit 1

if [ ! -z "$GIT_BRANCH" ]; then
	BRANCH=`basename $GIT_BRANCH`
else
	BRANCH=`git branch | awk '$1 == "*" {print $2}'`
fi

pusher=`echo $BRANCH | awk -F '-' '{print $2}'`

if [ -n "$pusher" ]; then
	grep "^$pusher:" /etc/passwd && \
		./test.sh --user hadoop --master $pusher-node1.maxwit.com \
			--slaves $pusher-node2.maxwit.com,$pusher-node3.maxwit.com
fi

