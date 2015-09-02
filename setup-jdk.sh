#!/bin/sh

if [ $# -eq 1 ]; then
	tarball=$1
elif [ ! -z $WITPUB ]; then
	tarball=$WITPUB/devel/java/jdk/jdk-7u67-linux-x64.tar.gz
else
	echo -e "usage: $0 [JDK]\n"
	exit 1
fi

if [ ! -e $tarball ]; then
	echo -e "'$tarball' does NOT exist!\n"
	exit 1
fi

jdk=`basename $tarball`

if [ -e .slaves ]; then
	slaves=`cat .slaves`
	hosts=(localhost $slaves)
else
	hosts=(localhost)
fi

total=${#hosts[@]}
count=1

for host in ${hosts[@]}
do
	echo "Installing JDK for $host [$count/$total] ..."

	ssh $host mkdir -vp bin
	scp ~/bin/install-jdk.sh $host:~/bin/
	scp $tarball $host:
	ssh $host ~/bin/install-jdk.sh $jdk

	((count++))
	echo
done
