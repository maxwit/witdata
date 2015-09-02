#!/bin/sh

top=$PWD

if [ $# != 1 ]; then
	cmd=`basename $0`
	echo -e "usage: $cmd <hadoop>\n"
	exit 1
fi

if [ -z "$JAVA_HOME" ]; then
	echo -e "JAVA_HOME not set!\n"
	exit 1
fi

if [ ! -e .slaves ]; then
	echo -e ".slaves does not exist!\n"
	exit 1
fi

slaves=(`cat .slaves`)
if [ ${#slaves[@]} = 0 ]; then
	echo -e "invalid .slaves!\n"
	exit 1
fi

tarball=$1

# FIXME
master=(`ifconfig | grep -o "[1-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"`)
master=${master[0]}
echo "master = $master"
echo "slaves = ${slaves[@]}"
echo

hadoop=`basename $1`
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

cp -v etc/hadoop/mapred-site.xml{.template,}
patch -p1 < $top/configure-cluster-sites.patch || exit 1
for xml in core-site hdfs-site mapred-site yarn-site
do
	sed -i "s/__MASTER__/$master/g" etc/hadoop/${xml}.xml || exit 1
done

for slave in ${slaves[@]}
do
	scp -r ../$hadoop ${slave}:
done

bin/hdfs namenode -format

sbin/start-all.sh

echo "********************************************"
echo "    run 'sbin/stop-all.sh to stop hadoop!'"
echo "********************************************"
echo
