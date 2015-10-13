function hbase_deploy
{
	sed -i -e "s:# export JAVA_HOME=.*:export JAVA_HOME=${home_dict[java]}:" \
		-e 's:#\s*export HBASE_LOG_DIR=.*:export HBASE_LOG_DIR=/var/log/$USER/hbase:' \
		conf/hbase-env.sh

	temp=`mktemp`

	cat > $temp << EOF
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://$master:9000/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>$zk_data_dir</value>
  </property>
EOF

	if [ $mode = 'cluster' ]; then
		quorum=`echo ${hosts[@]} | sed 's/\s\+/,/g'`
		echo "quorum=$quorum"
		cat >> $temp << EOF
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>$quorum</value>
  </property>
EOF
	fi

	sed -i "/<configuration>/r $temp" conf/hbase-site.xml

	rm -f $temp

	add_env HBASE_HOME $PWD
	add_path '$HBASE_HOME/bin'

	if [ $mode = 'cluster' ]; then
		truncate --size 0 conf/regionservers
		local count
		for ((count = 1; count < ${#hosts[@]}; count++))
		do
			echo ${hosts[$count]} >> conf/regionservers
		done

		echo ${hosts[1]} > conf/backup-masters
	fi

	if [ -e conf/regionservers ]; then
		echo "region servers:"
		cat conf/regionservers
	fi
	if [ -e conf/backup-masters ]; then
		echo "backup masters:"
		cat conf/backup-masters
	fi

	cp $top/service/hbase /etc/init.d/ || exit 1
	chmod +x /etc/init.d/hbase
}
