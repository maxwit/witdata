#!/bin/sh

function jdk_test()
{
	for host in $@
	do
		echo "Validating JDK: $host ..."
		scp target/check-jdk.sh $host:~/bin/
		ssh $host ~/bin/check-jdk.sh
	
		((count++))
		echo
	done
}

opt_test=0

for pub in $WITPUB /mnt/pub
do
	# FIXME
	_jdk="$pub/devel/java/jdk/jdk-7u67-linux-x64.tar.gz"
	if [ -e $_jdk ]; then
		opt_jdk=$_jdk
	fi
done

for opt in $@
do
	case $opt in
	-t|--test)
		opt_test=1
		;;
	-j=*|--jdk=*)
		opt_jdk=${opt#*=}
		;;
	*)
		echo -e "Invalid option '$opt'\n"
		exit 1
	esac
done

if [ -e .slaves ]; then
	slaves=`cat .slaves`
	hosts=(localhost $slaves)
else
	hosts=(localhost)
fi

if [ $opt_test -eq 1 ]; then
	jdk_test ${hosts[@]}
	echo
	exit 0
fi

if [ -z $opt_jdk ]; then
	echo -e "usage: $0 [options]\n"
	exit 1
fi

if [ ! -e $opt_jdk ]; then
	echo -e "'$opt_jdk' does NOT exist!\n"
	exit 1
fi

jdk=`basename $opt_jdk`

total=${#hosts[@]}
count=1

for host in ${hosts[@]}
do
	echo "Installing JDK [$count/$total]: $USER@$host ..."

	ssh $host mkdir -vp bin
	scp target/install-jdk.sh $host:~/bin/
	scp $opt_jdk $host:
	ssh $host ~/bin/install-jdk.sh $jdk

	((count++))
	echo
done

jdk_test ${hosts[@]}
echo
