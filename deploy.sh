#!/bin/sh

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

if [ -e .slaves ]; then
	mode="cluster"
else
	mode="pseudo"
fi

echo -e "configure hadoop as $mode mode!\n"

if [ $mode = "cluster" ]; then
	slaves=(`cat .slaves`)
	if [ ${#slaves[@]} = 0 ]; then
		echo -e "invalid .slaves: no slaves defined!\n"
		exit 1
	fi

	# FIXME
	master=(`ifconfig | grep -o "[1-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"`)
	master=${master[0]}

	echo "master = $master"
	echo "slaves = ${slaves[@]}"
	echo
fi


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
patch -p1 < $top/configure-${mode}-sites.patch || exit 1

if [ $mode = "cluster" ]; then
	cp -v $top/.slaves etc/hadoop/slaves

	for xml in core-site hdfs-site mapred-site yarn-site
	do
		sed -i "s/__MASTER__/$master/g" etc/hadoop/${xml}.xml || exit 1
	done

	# TODO: tar and copy
	for slave in ${slaves[@]}
	do
		scp -r ../$hadoop ${slave}:
	done
fi

bin/hdfs namenode -format

#echo "export HADOOP_HOME=\$HOME/$hadoop" >> ~/.bashrc

#sbin/start-all.sh
#echo "********************************************"
#echo "    run 'sbin/stop-all.sh to stop hadoop!'"
#echo "********************************************"
#echo

sbin/start-dfs.sh
echo "***************************"
echo "   run 'sbin/stop-dfs.sh'"
echo "***************************"
echo

sbin/start-yarn.sh
echo "***************************"
echo "   run 'sbin/stop-yarn.sh'"
echo "***************************"
echo
