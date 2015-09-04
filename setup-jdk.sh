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

function get_version
{
	ver=(`basename ${versions[$1]} | awk -F'-' '{print $2}' | awk -F'u' '{print $1}'`)
	echo $ver
}

for witpub in /mnt/witpub /mnt/hgfs/witpub
do
	versions=(`ls $witpub/devel/java/jdk/jdk-*-linux-*.tar.* 2>/dev/null`)

	s=${#versions[@]}
	if [ $s -gt 0 ]; then
		m=0
		ver_m=`get_version 0`

		for ((i=1; i<$s; i++))
		do
			ver_c=`get_version $i`

			if [ $ver_c -gt $ver_m ]; then
				m=$i
			fi
		done

		opt_jdk=${versions[$m]}
		break
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
