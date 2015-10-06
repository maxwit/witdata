function hadoop_deploy
{
	if [ -n "$HADOOP_HOME" ]; then
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
	temp=`mktemp -d`

	if [ $mode = "cluster" ]; then
		cat > $temp/core << EOF
	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://$master:9000</value>
	</property>
	<property>
		<name>hadoop.tmp.dir</name>
		<value>$data_root/tmp</value>
	</property>
EOF
		cat > $temp/hdfs << EOF
	<property>
		<name>dfs.replication</name>
		<value>1</value>
	</property>
	<property>
		<name>dfs.namenode.secondary.http-address</name>
		<value>$master:9001</value>
	</property>
EOF
		cat > $temp/mapred << EOF
	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
	</property>
	<property>
		<name>mapreduce.jobhistory.address</name>
		<value>$master:10020</value>
	</property>
	<property>
		<name>mapreduce.jobhistory.webapp.address</name>
		<value>$master:19888</value>
	</property>
EOF
		cat > $temp/yarn << EOF
	<property>
		<name>yarn.nodemanager.aux-services</name>
		<value>mapreduce_shuffle</value>
	</property>
	<property>
		<name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
		<value>org.apache.hadoop.mapred.ShuffleHandler</value>
	</property>
	<property>
		<name>yarn.resourcemanager.address</name>
		<value>$master:8032</value>
	</property>
	<property>
		<name>yarn.resourcemanager.scheduler.address</name>
		<value>$master:8030</value>
	</property>
	<property>
		<name>yarn.resourcemanager.resource-tracker.address</name>
		<value>$master:8031</value>
	</property>
	<property>
		<name>yarn.resourcemanager.admin.address</name>
		<value>$master:8033</value>
	</property>
	<property>
		<name>yarn.resourcemanager.webapp.address</name>
		<value>$master:8088</value>
	</property>
EOF
	else
		cat > $temp/core << EOF
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
	<property>
		<name>hadoop.tmp.dir</name>
		<value>$data_root/tmp</value>
	</property>
EOF
		cat > $temp/hdfs << EOF
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
EOF
		cat > $temp/mapred << EOF
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
EOF
		cat > $temp/yarn << EOF
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
EOF
	fi

	for cfg in core hdfs mapred yarn
	do
		sed -i "/<configuration>/r $temp/$cfg" etc/hadoop/$cfg-site.xml || exit 1
	done
	rm -rf $temp

	if [ $mode = "cluster" ]; then
		truncate --size 0 etc/hadoop/slaves
		for slave in ${slaves[@]}
		do
			echo $slave >> etc/hadoop/slaves
		done

		for slave in ${slaves[@]}
		do
			$TOP/fast-scp $PWD ${slave} || exit 1
		done
		echo
	fi

	add_export HADOOP_HOME $PWD
	#add_export HADOOP_CONF_DIR '$HADOOP_HOME/etc/hadoop'
	add_path '$HADOOP_HOME/bin'

	hdfs namenode -format

	sbin/start-dfs.sh || exit 1
	echo
	sbin/start-yarn.sh || exit 1
	echo
	sbin/mr-jobhistory-daemon.sh start historyserver || exit 1
	echo

	# FIXME: right here?
	# mkdir -p tmp hdfs hdfs/data hdfs/name
	hadoop fs -ls /
	hadoop fs -mkdir /tmp
	hadoop fs -chmod g+w /tmp
}

function hadoop_destroy
{
	if [ -z "$HADOOP_HOME" ]; then
		echo "hadoop not installed!"
		return 0
	fi

	if [ -d $HADOOP_HOME ]; then
		$HADOOP_HOME/sbin/stop-dfs.sh || exit 1
		$HADOOP_HOME/sbin/stop-yarn.sh || exit 1
		$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh stop historyserver || exit 1
	fi
	echo

	for host in localhost `cat $HADOOP_HOME/etc/hadoop/slaves`
	do
		echo "removing $HADOOP_HOME @ $host"
		ssh $host << EOF
rm -rf $HADOOP_HOME
EOF
	done

	sed -i '/HADOOP_HOME/d' $profile
	#del_export HADOOP_CONF_DIR
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
	#ssh $master hadoop-2.7.1/bin/hadoop fs -rm /$temp || exit 1
	echo
}
