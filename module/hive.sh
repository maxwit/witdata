function hive_deploy
{
	if [ "$HIVE_HOME" != "" ]; then
		echo -e "Hive already installed!\n"
		return 1
	fi

	#if [ "$HADOOP_HOME" == "" ]; then
	#	echo -e "hadoop not installed!\n"
	#	return 1
	#fi

	extract $hive
	cd $HOME/$hive || return 1

	add_env HIVE_HOME $PWD
	add_env HIVE_CONF_DIR '$HIVE_HOME/conf'
	add_path '$HIVE_HOME/bin'

	for slave in ${slaves[@]}
	do
		$TOP/fast-scp $PWD $slave
		scp $profile $slave:$profile
	done
}

function hive_destroy
{
	if [ -z "$HIVE_HOME" ]; then
		echo "hive not installed!"
		return 0
	fi

	for host in ${hosts[@]}
	do
		echo "removing $HIVE_HOME @ $host"

		if [ $host = $master ]; then
			prefix=""
		else
			prefix="ssh $host "
		fi

		${prefix}rm -rf $HIVE_HOME
		#${prefix}rm -rf $data_root/hbase
		${prefix}sed -i '/HIVE_HOME/d' $profile
	done
}

function hive_start
{
	return 0
}

function hive_stop
{
	return 0
}

function hive_test
{
	temp=`mktemp`

	cat > $temp << EOF
master=node1.jerry
slave1=node2.jerry
slave2=node3.jerry
EOF

	hive << EOF
create table if not exists test (name string,value string)
row format delimited
fields terminated by '=';
load data local inpath '$temp'
overwrite into table test;
select * from test;
drop table test;
exit; 
EOF

	rm $temp
}
