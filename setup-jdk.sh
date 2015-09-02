#!/bin/sh

function jdk_test()
{
	for host in $@
	do
		echo "validating JDK on $host ..."
		scp target/check-jdk.sh $host:~/bin/
		ssh $host ~/bin/check-jdk.sh
	
		((count++))
		echo
	done
}

opt_test=0
if [ ! -z $WITPUB ]; then
	opt_jdk=$WITPUB/devel/java/jdk/jdk-7u67-linux-x64.tar.gz
fi

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
	echo "Installing JDK for $host [$count/$total] ..."

	ssh $host mkdir -vp bin
	scp target/install-jdk.sh $host:~/bin/
	scp $opt_jdk $host:
	ssh $host ~/bin/install-jdk.sh $jdk

	((count++))
	echo
done

jdk_test ${hosts[@]}
echo
