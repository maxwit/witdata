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

	temp=`mktemp`
	cat > $temp << EOF
<configuration>
  <property>
    <name>hbase.rootdir</name>
    <value>file://$data_root/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>$data_root/zookeeper</value>
  </property>
</configuration>
EOF
	sed -i "/<configuration>/r $temp" conf/hbase-site.xml	
	rm $temp

	./bin/start-hbase.sh
}

function hbase_destroy
{
	# FIXME
	HBASE_HOME=$HOME/$hbase

	if [ ! -d $HBASE_HOME ]; then
		return 0;
	fi

	cd $HBASE_HOME
	./bin/stop-hbase.sh

	rm -rf $HBASE_HOME || exit 1
	rm -rf $data_root/hbase

	# del_export HBASE_HOME
}

function hbase_validate
{
	# FIXME
	HBASE_HOME=$HOME/$hbase

	if [ ! -d "$HBASE_HOME" ]; then
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
