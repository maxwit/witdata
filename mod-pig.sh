function pig_deploy
{
	if [ "$PIG_HOME" != "" ]; then
		echo -e "Pig already installed!\n"
		return 1
	fi

	#if [ "$HADOOP_HOME" == "" ]; then
	#	echo -e "hadoop not installed!\n"
	#	return 1
	#fi

	extract $pig
	cd $HOME/$pig

	add_env PIG_HOME $PWD
	add_path '$PIG_HOME/bin'

	for slave in ${slaves[@]}
	do
		$TOP/fast-scp $PWD $slave
		scp $profile $slave:$profile
	done
}

function pig_destroy
{
	if [ -z "$PIG_HOME" ]; then
		echo "pig not installed!"
		return 0
	fi

	for host in ${hosts[@]}
	do
		echo "removing $PIG_HOME @ $host"

		if [ $host = $master ]; then
			prefix=""
		else
			prefix="ssh $host "
		fi

		${prefix}rm -rf $PIG_HOME
		${prefix}sed -i '/PIG_HOME/d' $profile
	done
}

function pig_start
{
	return 0
}

function pig_stop
{
	return 0
}

function pig_test
{
	temp=`mktemp`
	
	cat > $temp << EOF
master  node1.jerry
slave1  node2.jerry
slave2  node3.jerry
EOF
	
	hdfs dfs -put $temp /tmp
	
	pig << EOF
test = load '$temp' as (slaves:chararray, domain:chararray);
describe test;
dump test;
\q
EOF

	rm $temp
}
