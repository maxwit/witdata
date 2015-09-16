#!/bin/sh --login

cd `dirname $0`
top=$PWD

if [ $# != 1 ]; then
	cmd=`basename $0`
	echo -e "usage: $cmd <hadoop>\n"
	exit 1
fi

tarball=$1

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

echo -e "configure hadoop as $mode mode!\n"
echo "hosts = ${hosts[@]}"

hadoop=`basename $tarball`
hadoop=${hadoop%%.tar.*}

cd
echo "extracting $hadoop ..."
# FIXME
rm -rf $hadoop /tmp/hadoop-$USER
tar xf $tarball || exit 1

# TODO:
# mkdir -p tmp hdfs hdfs/data hdfs/name

cd $hadoop
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

	# TODO: tar and copy
	for slave in ${slaves[@]}
	do
		ssh ${slave} rm -rf $hadoop
		scp -r ../$hadoop ${slave}:
	done
fi

bin/hdfs namenode -format

grep HADOOP_HOME ~/.profile || echo "export HADOOP_HOME=\$HOME/$hadoop" >> ~/.profile

sbin/start-dfs.sh
echo

sbin/start-yarn.sh
echo
