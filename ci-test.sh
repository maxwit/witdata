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

echo -n "copying $wd to $user@$master .."
ssh $user@$master rm -rf $wd
echo '.'
if [ -d .git ]; then
	temp=`mktemp -d`
	cp -r $PWD $temp
	rm -rf $temp/$wd/.git*
	scp -r $temp/$wd $user@$master:
else
	scp -r $PWD $user@$master:
fi
echo

ssh $user@$master $wd/deploy-all.sh || exit 1
