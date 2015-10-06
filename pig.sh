function pig_deploy
{
	if [ "$PIG_HOME" != "" ]; then
		echo -e "Pig already installed!\n"
		exit 1
	fi

	if [ "$HADOOP_HOME" == "" ]; then
		echo -e "hadoop not installed!\n"
		exit 1
	fi

	extract $pig

	add_export PIG_HOME "\$HOME/$pig"
	add_export PIG_CLASSPATH '$HADOOP_HOME/etc/hadoop'
	add_path '$PIG_HOME/bin'
}

function pig_destroy
{
	[ -z "$PIG_HOME" ] && exit 0

	if [ -d $PIG_HOME ]; then
		rm -rf $PIG_HOME
	fi

	del_export PIG_HOME
	del_export PIG_CLASSPATH
	del_path '$PIG_HOME/bin'
}

function pig_validate
{
	temp=`mktemp`
	
	cat > $temp << EOF
master  node1.jerry
slave1  node2.jerry
slave2  node3.jerry
EOF
	
	$HADOOP_HOME/bin/hdfs dfs -put $temp /tmp
	
	$PIG_HOME/bin/pig << EOF
test = load '$temp' as (slaves:chararray,demain:chararray);
describe test;
dump test;
\q
EOF
	rm $temp
}
