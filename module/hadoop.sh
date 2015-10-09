function hadoop_deploy
{
	if [ -n "$HADOOP_HOME" ]; then
		echo -e "hadoop already installed ($HADOOP_HOME)!\n"
		return 0
	fi

	rm -rf $apps_root/$hadoop
	extract $hadoop
	cd $apps_root/$hadoop
	echo

	sed -i "s:export JAVA_HOME=\${JAVA_HOME}:export JAVA_HOME=${JAVA_HOME}:" etc/hadoop/hadoop-env.sh

	bin/hadoop version || return 1
	echo

	temp=`mktemp -d`

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
EOF

	cat > $temp/yarn << EOF
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
EOF

	if [ $mode = "cluster" ]; then
		cat >> $temp/mapred << EOF
	<property>
		<name>mapreduce.jobhistory.address</name>
		<value>$master:10020</value>
	</property>
	<property>
		<name>mapreduce.jobhistory.webapp.address</name>
		<value>$master:19888</value>
	</property>
EOF

		cat >> $temp/yarn << EOF
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
	fi

	cp etc/hadoop/mapred-site.xml{.template,}
	for cfg in core hdfs mapred yarn
	do
		sed -i "/<configuration>/r $temp/$cfg" etc/hadoop/$cfg-site.xml || return 1
	done

	rm -rf $temp

	echo -n "formatting namenode ... "
	bin/hdfs namenode -format > $log 2>&1 || return 1
	echo "done"

	add_env HADOOP_HOME $PWD
	add_env HADOOP_CONF_DIR '$HADOOP_HOME/etc/hadoop'
	add_path '$HADOOP_HOME/bin'

	if [ $mode = "cluster" ]; then
		truncate --size 0 etc/hadoop/slaves
		for slave in ${slaves[@]}
		do
			echo $slave >> etc/hadoop/slaves
		done

		for slave in ${slaves[@]}
		do
			$TOP/fast-scp $PWD $slave || return 1
			scp $profile $slave:$profile
		done
	fi
}

function hadoop_destroy
{
	if [ -z "$HADOOP_HOME" ]; then
		echo "hadoop not installed!"
		return 0
	fi

	#if [ -e $HADOOP_HOME/etc/hadoop/slaves ]; then
	#	local slaves=`cat $HADOOP_HOME/etc/hadoop/slaves`
	#fi

	for host in ${hosts[@]}
	do
		echo "removing $hadoop @ $host"

		if [ $host = $master ]; then
			prefix=""
		else
			prefix="ssh $host "
		fi

		${prefix}rm -rf $HADOOP_HOME
		${prefix}sed -i '/HADOOP_/d' $profile
	done
}

function hadoop_start
{
	if [ -n "$HADOOP_HOME" -a -d "$HADOOP_HOME" ]; then
		$HADOOP_HOME/sbin/start-dfs.sh || return 1
		echo
		$HADOOP_HOME/sbin/start-yarn.sh || return 1
		echo
		$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver || return 1
		echo
	fi

	# FIXME: right here?
	hadoop fs -ls / || return 1
	hadoop fs -mkdir -p /tmp /user || return 1
	hadoop fs -chmod g+w /tmp /user || return 1
	hadoop fs -ls / || return 1
}

function hadoop_stop
{
	if [ -n "$HADOOP_HOME" -a -d "$HADOOP_HOME" ]; then
		$HADOOP_HOME/sbin/stop-dfs.sh || return 1
		$HADOOP_HOME/sbin/stop-yarn.sh || return 1
		$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh stop historyserver || return 1
	fi
}

function hadoop_test
{
	# FIXME
	master=`hostname`
	if [ -z "$HADOOP_HOME" ]; then
		echo "not installed"
		return 1
	else
		echo "$HADOOP_HOME"
	fi
	echo

	temp=`mktemp`
	date > $temp

	echo "putting $temp to master ..."
	$HADOOP_HOME/bin/hadoop fs -put $temp /tmp/ || return 1
	echo

	for slave in `cat $HADOOP_HOME/etc/hadoop/slaves`
	do
		echo "checking '$slave' ..."
		ssh $slave $HADOOP_HOME/bin/hadoop fs -ls $temp || return 1
	done
	echo

	echo "removing $temp ..."
	$HADOOP_HOME/bin/hadoop fs -rm $temp || return 1
	echo
}
