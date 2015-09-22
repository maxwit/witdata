#!/bin/sh --login

cd `dirname $0`
top=$PWD

if [ -z "$JAVA_HOME" ]; then
	echo -e "JAVA_HOME not set!\n"
	exit 1
fi

if [ "$HADOOP_HOME" != "" ]; then
	echo -e "Warning: previous hadoop ($HADOOP_HOME) already installed!\n"
fi

. ./parse-config.sh

if [ ${#slaves[@]} -ne 0 ]; then
	mode="cluster"
else
	mode="pseudo"
fi

echo -e "configure hadoop in $mode mode!\n"
echo "Cluster nodes: ${hosts[@]}"

echo "extracting $hadoop ..."
tar xf $repo/${hadoop}.tar.gz -C $HOME || exit 1

cd $HOME/$hadoop

sed -i "s:export JAVA_HOME=\${JAVA_HOME}:export JAVA_HOME=${JAVA_HOME}:" etc/hadoop/hadoop-env.sh

bin/hadoop version || exit 1
echo

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

	for slave in ${slaves[@]}
	do
		./tar-and-scp $PWD ${slave} || exit 1
	done
	echo
fi

bin/hdfs namenode -format

if [ -e /etc/redhat-release ]; then
	sh_config="$HOME/.bashrc"
else
	sh_config="$HOME/.profile"
fi

grep HADOOP_HOME $sh_config || echo "export HADOOP_HOME=$PWD" >> $sh_config

sbin/start-dfs.sh || exit 1
echo

sbin/start-yarn.sh || exit 1
echo

# FIXME: right here?
# mkdir -p tmp hdfs hdfs/data hdfs/name
bin/hadoop fs -ls /
bin/hadoop fs -mkdir /tmp
bin/hadoop fs -chmod g+w /tmp

echo 'Done!'
echo
