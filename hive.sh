function hive_deploy
{
	if [ "$HIVE_HOME" != "" ]; then
		echo -e "Hive already installed!\n"
		exit 1
	fi

	if [ "$HADOOP_HOME" == "" ]; then
		echo -e "hadoop not installed!\n"
		exit 1
	fi

	extract $hive

	add_export HIVE_HOME "\$HOME/$hive"
	add_path '$HIVE_HOME/bin'
}

function hive_destroy
{
	[ -z "$HIVE_HOME" ] && exit 0

	if [ -d $HIVE_HOME ]; then
		rm -rf $HIVE_HOME
	fi

	del_export HIVE_HOME
	del_path '$HIVE_HOME/bin'
}

function hive_validate
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
}
