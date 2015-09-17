#!/bin/sh

cwd=`basename $PWD`

for witpub in /mnt/witpub /mnt/hgfs/witpub
do
	hl=(`ls $witpub/devel/hadoop/hadoop-*`)
	if [ ${#hl[@]} -gt 0 ]; then
		tarball=${hl[-1]}
		break
	fi
done

if [ -z "$tarball" ]; then
	echo "hadoop not found!"
	exit 1
fi

hadoop=`basename $tarball`

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

. ./parse-config.sh

echo "copying $cwd to $user@$master ..."
cd ..
tar cf /tmp/${cwd}.tar $cwd --exclude .git
cd - > /dev/null
scp /tmp/${cwd}.tar $user@$master:/tmp/
ssh $user@$master tar xf /tmp/${cwd}.tar || exit 1
ssh $user@$master rm /tmp/${cwd}.tar
echo

#ssh $user@$master $cwd/setup-ssh.sh
#ssh $user@$master $cwd/setup-jdk.sh -t

echo "destroying $user@$master ..."
ssh $user@$master ${cwd}/destroy.sh || exit 1
echo

echo "copying $hadoop to $user@$master ..."
scp $tarball $user@$master:/tmp/
echo

echo "deploying ${hadoop%.tar*} ..."
ssh $user@$master ${cwd}/deploy.sh /tmp/$hadoop || exit 1
echo

echo "removing /tmp/${hadoop} ..."
ssh $user@$master rm /tmp/${hadoop}
echo
