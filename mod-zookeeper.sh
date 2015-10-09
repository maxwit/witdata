function zookeeper_deploy
{
	local count

	if [ "$ZOOKEEPER_HOME" != "" ]; then
		echo -e "zookeeper already installed!\n"
		return 1
	fi

	rm -rf $HOME/$zk
	extract $zk
	cd $HOME/$zk

	echo
	cp -v conf/zoo{_sample,}.cfg || return 1
	data_dir=$data_root/zookeeper
	sed -i "s:^dataDir=.*:dataDir=$data_dir:" conf/zoo.cfg
	if [ $mode = "cluster" ]; then
		count=1
		for host in ${hosts[@]}
		do
			echo "server.$count=$host:2888:3888" >> conf/zoo.cfg
			((count++))
		done
	fi
	sed '/^#/d' conf/zoo.cfg 
	echo

	add_env ZOOKEEPER_HOME $PWD
	add_path '$ZOOKEEPER_HOME/bin'

	count=1
	temp=`mktemp`

	for host in ${hosts[@]}
	do
		echo "deploying $zk @ $host ..."

		ssh $host mkdir -p $data_dir

		if [ $mode = "cluster" ]; then
			echo $count > $temp
			((count++))
			scp $temp $host:$data_dir/myid

			if [ $host != $master ]; then
				$TOP/fast-scp $PWD $host || return 1
				scp $profile $host:$profile
			fi
		fi

		echo
	done

	rm $temp
}

function zookeeper_destroy
{
	if [ -z "$ZOOKEEPER_HOME" ]; then
		echo "zookeeper not installed!"
		return 0
	fi

	for host in ${hosts[@]}
	do
		echo "removing $zk @ $host ..."

		if [ $host = $master ]; then
			prefix=""
		else
			prefix="ssh $host "
		fi

		${prefix}rm -rf $ZOOKEEPER_HOME
		${prefix}sed -i '/ZOOKEEPER_HOME/d' $profile
	done
}

function zookeeper_start
{
	for host in ${hosts[@]}
	do
		ssh $host << EOF
echo "host: `hostname`"
zkServer.sh start || return 1
EOF
	done
}

function zookeeper_stop
{
	for host in ${hosts[@]}
	do
		ssh $host << EOF
echo "host: `hostname`"
zkServer.sh stop || return 1
EOF
	done
}

function zookeeper_test
{
	if [ -z "$ZOOKEEPER_HOME" -o ! -d "$ZOOKEEPER_HOME" ]; then
		echo "not installed"
		return 1
	fi

	zkCli.sh -server $master:2181 << EOF
create /zk_demo demo1
ls /
get /zk_demo
set /zk_demo demo2
get /zk_demo
delete /zk_demo
EOF
}
