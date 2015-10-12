function hadoop_deploy
{
	sed -i "s:export JAVA_HOME=\${JAVA_HOME}:export JAVA_HOME=${JAVA_HOME}:" etc/hadoop/hadoop-env.sh

	bin/hadoop version || return 1

	local temp=`mktemp -d`

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
	sudo -u $hadoop_user bin/hdfs namenode -format > $log 2>&1 || return 1
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
	fi
}

function hadoop_init
{
	sudo -i $hadoop_user hadoop fs -mkdir -p /tmp /user || return 1
	sudo -i $hadoop_user hadoop fs -chmod g+w /tmp /user || return 1
	sudo -i $hadoop_user hadoop fs -ls / || return 1
}

function hadoop_destroy
{
	sed -i '/HADOOP_/d' $profile
}
