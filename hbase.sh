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
		truncate --size 0 conf/regionservers
		local count
		for ((count = 1; count < ${#hosts[@]}; count++))
		do
			echo ${hosts[$count]} >> conf/regionservers
		done

		echo ${hosts[1]} > conf/backup-masters

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
		sed -i "/<configuration>/r $temp" conf/hbase-site.xml	

		for slave in ${slaves[@]}
		do
			$TOP/fast-scp $PWD ${slave} || exit 1
		done
	else
		cat > $temp << EOF
  <property>
    <name>hbase.rootdir</name> <value>file://$data_root/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>$data_root/zookeeper</value>
  </property>
EOF
		sed -i "/<configuration>/r $temp" conf/hbase-site.xml	
	fi
	rm $temp

	./bin/start-hbase.sh
}

function hbase_destroy
{
	# FIXME
	HBASE_HOME=$HOME/$hbase

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

	# del_export HBASE_HOME
}

function hbase_validate
{
	# FIXME
	HBASE_HOME=$HOME/$hbase

	if [ ! -d $HBASE_HOME ]; then
		echo "not installed"
		exit 1
	else
		echo "$HBASE_HOME"
	fi
	echo

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
