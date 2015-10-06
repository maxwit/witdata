function hbase_deploy
{
	if [ "$HBASE_HOME" != "" -a -d "$HBASE_HOME" ]; then
		echo -e "hbase already installed ($HBASE_HOME)!\n"
		return 0
	fi

	echo -e "configure hbase in $mode mode!\n"
	echo "Cluster nodes: ${hosts[@]}"

	extract $hbase-bin
	cd $HOME/$hbase

	sed -i "s:# export JAVA_HOME=.*:export JAVA_HOME=${JAVA_HOME}:" conf/hbase-env.sh

	temp=`mktemp`
	if [ $mode = 'cluster' ]; then
		quorum=`echo ${hosts[@]} | sed 's/\s\+/,/g'`
		cat > $temp << EOF
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://localhost:8020/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>$quorum</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>$data_root/zookeeper</value>
  </property>
EOF
	else
		# FIXME: pseudo instead of standalone
		cat > $temp << EOF
  <property>
    <name>hbase.rootdir</name>
	<value>file://$data_root/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>$data_root/zookeeper</value>
  </property>
EOF
	fi
	sed -i "/<configuration>/r $temp" conf/hbase-site.xml
	rm $temp

	if [ $mode = 'cluster' ]; then
		truncate --size 0 conf/regionservers
		local count
		for ((count = 1; count < ${#hosts[@]}; count++))
		do
			echo ${hosts[$count]} >> conf/regionservers
		done

		echo "region servers:"
		cat conf/regionservers
		echo

		echo ${hosts[1]} > conf/backup-masters

		echo "backup masters:"
		cat conf/backup-masters
		echo

		for slave in ${slaves[@]}
		do
			$TOP/fast-scp $PWD ${slave} || exit 1
		done
	fi

	add_export HBASE_HOME

	./bin/start-hbase.sh
}

function hbase_destroy
{
	if [ -z "$HBASE_HOME" ]; then
		return 0
	fi

	if [ ! -d $HBASE_HOME ]; then
		echo "$HBASE_HOME does not exist (skipped)"	
		return 0
	fi

	cd $HBASE_HOME
	echo "stoping $hbasei ..."
	./bin/stop-hbase.sh

	for slave in localhost `cat conf/regionservers`
	do
		echo "removing $HBASE_HOME @ $slave"
		ssh $slave << EOF
[ ! -d "$HBASE_HOME" ] && exit 0
rm -rf $HBASE_HOME
rm -rf $data_root/hbase
EOF
	done

	del_export HBASE_HOME
}

function hbase_validate
{
	if [ -z "$HBASE_HOME" -o ! -d "$HBASE_HOME" ]; then
		echo "not installed"
		exit 1
	fi

	cd $HBASE_HOME || exit 1

	./bin/hbase shell << EOF
create 'test', 'cf'
list 'test'
put 'test', 'row1', 'cf:a', 'value1'
put 'test', 'row2', 'cf:b', 'value2'
put 'test', 'row3', 'cf:c', 'value3'
scan 'test'
get 'test', 'row1'
disable 'test'
enable 'test'
disable 'test'
drop 'test'
EOF
}
