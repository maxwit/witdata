#!/bin/sh

if [ $# != 1 ]; then
	echo -e "usage: $0 <JDK>\n"
	exit 1
fi

jdk=$1
ljdk=`basename $jdk`

cp -v target/install-jdk.sh ~/bin/
echo "installing JDK for localhost ..."
~/bin/install-jdk.sh $jdk

slaves=(`cat .slaves`)
if [ ${#slaves[@]} = 0 ]; then
	echo -e "none slave defined!\n"
	exit 1
fi

for slave in ${slaves[@]}
do
	echo "installing JDK for $slave ..."
	ssh $slave mkdir -vp bin
	scp ~/bin/install-jdk.sh $slave:~/bin/
	scp $jdk $slave:
	ssh $slave ~/bin/install-jdk.sh $ljdk
	echo
done
