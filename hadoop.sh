function hadoop_deploy
{
	if [ "$HADOOP_HOME" != "" ]; then
		echo -e "hadoop already installed ($HADOOP_HOME)!\n"
		return 0
	fi

	echo -e "configure hadoop in $mode mode!\n"
	echo "Cluster nodes: ${hosts[@]}"

	extract $hadoop
	cd $HOME/$hadoop

	sed -i "s:export JAVA_HOME=\${JAVA_HOME}:export JAVA_HOME=${JAVA_HOME}:" etc/hadoop/hadoop-env.sh

	bin/hadoop version || exit 1
	echo

	### configure sites ###
	cp -v etc/hadoop/mapred-site.xml{.template,}
	patch -p1 < $TOP/patch/configure-${mode}-sites.patch || exit 1

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
			$TOP/fast-scp $PWD ${slave} || exit 1
		done
		echo
	fi

	bin/hdfs namenode -format

	update_export HADOOP_HOME $PWD

	sbin/start-dfs.sh || exit 1
	echo

	sbin/start-yarn.sh || exit 1
	echo

	# FIXME: right here?
	# mkdir -p tmp hdfs hdfs/data hdfs/name
	bin/hadoop fs -ls /
	bin/hadoop fs -mkdir /tmp
	bin/hadoop fs -chmod g+w /tmp
}

function hadoop_destroy
{
	[ -z "$HADOOP_HOME" ] && return 0

	if [ -d $HADOOP_HOME ]; then
		$HADOOP_HOME/sbin/stop-dfs.sh || exit 1
		$HADOOP_HOME/sbin/stop-yarn.sh || exit 1
	fi

	for host in localhost `cat $HADOOP_HOME/etc/hadoop/slaves`
	do
		echo "removing $HADOOP_HOME @ $host"
		ssh $host << EOF
rm -rf $HADOOP_HOME
rm -rf /tmp/hadoop-$USER
EOF
	done

	del_export HADOOP_HOME
	# echo "'export HADOOP_HOME' removed from $sh_config" $sh_config
}

function hadoop_validate
{
	# FIXME
	master=`hostname`
	if [ -z "$HADOOP_HOME" ]; then
		echo "not installed"
		exit 1
	else
		echo "$HADOOP_HOME"
	fi
	echo

	temp=`mktemp`
	date > $temp

	echo "putting $temp to master ..."
	$HADOOP_HOME/bin/hadoop fs -put $temp /tmp/ || exit 1
	echo

	for slave in `cat $HADOOP_HOME/etc/hadoop/slaves`
	do
		echo "checking '$slave' ..."
		ssh $slave $HADOOP_HOME/bin/hadoop fs -ls $temp || exit 1
	done
	echo

	echo "removing $temp ..."
	#ssh $user@$master hadoop-2.7.1/bin/hadoop fs -rm /$temp || exit 1
	echo
}
