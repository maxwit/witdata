#!/bin/sh --login

cd `dirname $0`
top=$PWD

if [ "$HADOOP_HOME" != "" ]; then
	echo -e "Warning: previous hadoop ($HADOOP_HOME) already installed!\n"
fi

if [ -z "$JAVA_HOME" ]; then
	echo -e "JAVA_HOME not set!\n"
	exit 1
fi

. ./parse-config.sh

if [ ${#slaves[@]} -ne 0 ]; then
	mode="cluster"
else
	mode="pseudo"
fi

echo -e "configure hadoop in $mode mode!\n"
echo "All nodes: ${hosts[@]}"

repo='/mnt/witpub/devel/hadoop/'

echo "extracting $hadoop ..."
tar xf $repo/${hadoop}.tar.gz -C $HOME || exit 1

cd $HOME/$hadoop

sed -i "s:export JAVA_HOME=\${JAVA_HOME}:export JAVA_HOME=${JAVA_HOME}:" etc/hadoop/hadoop-env.sh

bin/hadoop version || exit 1
echo

# TODO:
# mkdir -p tmp hdfs hdfs/data hdfs/name

### configure sites ###
cp -v etc/hadoop/mapred-site.xml{.template,}
patch -p1 < $top/patch/configure-${mode}-sites.patch || exit 1

if [ $mode = "cluster" ]; then
	truncate --size 0 etc/hadoop/slaves
	for slave in ${slaves[@]}
	do
		echo $slave >> etc/hadoop/slaves
	done

	for cfg in core hdfs mapred yarn
	do
		sed -i "s/__MASTER__/$master/g" etc/hadoop/${cfg}-site.xml || exit 1
	done

	# TODO: tar and copy
	for slave in ${slaves[@]}
	do
		echo -n "copying $hadoop to $slave .."
		ssh $slave rm -rf $hadoop || exit 1
		echo '.'
		scp -r $PWD ${slave}: || exit 1
	done
	echo
fi

bin/hdfs namenode -format

grep HADOOP_HOME ~/.profile || echo "export HADOOP_HOME=\$HOME/$hadoop" >> ~/.profile

sbin/start-dfs.sh || exit 1
echo

sbin/start-yarn.sh || exit 1
echo

echo 'Done!'
echo
