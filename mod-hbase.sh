function hbase_deploy
{
	if [ "$HBASE_HOME" != "" -a -d "$HBASE_HOME" ]; then
		echo -e "hbase already installed ($HBASE_HOME)!\n"
		return 0
	fi

	rm -rf $HOME/$hbase
	extract $hbase-bin
	cd $HOME/$hbase

	sed -i "s:# export JAVA_HOME=.*:export JAVA_HOME=${JAVA_HOME}:" conf/hbase-env.sh

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
    <value>$data_root/zookeeper</value>
  </property>
EOF

	if [ $mode = 'cluster' ]; then
		quorum=`echo ${hosts[@]} | sed 's/\s\+/,/g'`
		cat >> $temp << EOF
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>$quorum</value>
  </property>
EOF
	fi

	sed -i "/<configuration>/r $temp" conf/hbase-site.xml

	rm $temp

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

		#echo "region servers:"
		#cat conf/regionservers
		#echo

		#echo "backup masters:"
		#cat conf/backup-masters
		#echo

		for slave in ${slaves[@]}
		do
			$TOP/fast-scp $PWD $slave || exit 1
			scp $profile $slave:$profile
		done
	fi
}

function hbase_destroy
{
	if [ -z "$HBASE_HOME" ]; then
		echo "hbase not installed!"
		return 0
	fi

	for host in ${hosts[@]}
	do
		echo "removing $HBASE_HOME @ $host"

		if [ $host = $master ]; then
			prefix=""
		else
			prefix="ssh $host "
		fi

		${prefix}rm -rf $HBASE_HOME
		#${prefix}rm -rf $data_root/hbase
		${prefix}sed -i '/HBASE_HOME/d' $profile
	done
}

function hbase_start
{
	start-hbase.sh
}

function hbase_stop
{
	stop-hbase.sh
}

function hbase_test
{
	if [ -z "$HBASE_HOME" -o ! -d "$HBASE_HOME" ]; then
		echo "$hbase not installed"
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
