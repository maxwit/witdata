function hive_deploy
{
	if [ "$HIVE_HOME" != "" ]; then
		echo -e "Hive already installed!\n"
		return 1
	fi

	if [ "$HADOOP_HOME" == "" ]; then
		echo -e "hadoop not installed!\n"
		return 1
	fi

	echo "extracting $hive ..."
	tar xf $repo/${hive}.tar.gz -C $HOME || exit 1

	if [ -e /etc/redhat-release ]; then
		sh_config="$HOME/.bashrc"
	else
		sh_config="$HOME/.profile"
	fi

	cat >> $sh_config << EOF
export HIVE_HOME=\$HOME/$hive
export HIVE_CONF_DIR=\$HIVE_HOME/conf
export PATH=\$PATH:\$HIVE_HOME/bin
EOF
}

function hive_destroy
{
	[ -z "$HIVE_HOME" ] && exit 0

	if [ -d $HIVE_HOME ]; then
		rm -rf $HIVE_HOME
	fi

	if [ -e /etc/redhat-release ]; then
		sh_config="$HOME/.bashrc"
	else
		sh_config="$HOME/.profile"
	fi

	sed -i '/\<HIVE_/d' $sh_config
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
