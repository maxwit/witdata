function zookeeper_deploy
{
	local count

	if [ "$ZOOKEEPER_HOME" != "" ]; then
		echo -e "zookeeper already installed!\n"
		exit 1
	fi

	echo -e "configure zookeeper in $mode mode!\n"
	echo "Cluster nodes: ${hosts[@]}"

	extract $zk
	cd $HOME/$zk
	local zk_home=$PWD

	echo
	cp -v conf/zoo{_sample,}.cfg || exit 1
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

	count=1
	for host in ${hosts[@]}
	do
		echo "deploying $zk @ $host ..."
		if [ $host != $master ]; then
			$TOP/fast-scp $PWD $host || exit 1
		fi

		ssh $host << EOF
mkdir -p $data_dir
if [ $mode = "cluster" ]; then
	echo $count > $data_dir/myid
fi
cd $zk_home
bin/zkServer.sh start
EOF

		((count++))

		echo
	done

	add_export ZOOKEEPER_HOME $zk_home
}

function zookeeper_destroy
{
	if [ -z "$ZOOKEEPER_HOME" ]; then
		return 0
	fi

	for host in ${hosts[@]}
	do
		ssh $host << EOF
[ ! -d "$ZOOKEEPER_HOME" ] && exit 0
zk=`basename $ZOOKEEPER_HOME`
echo "stoping $zk ..."
cd $ZOOKEEPER_HOME
bin/zkServer.sh stop
echo "removing $zk ..."
rm -rf $ZOOKEEPER_HOME
rm -rf $data_root/zookeeper
EOF
	done

	sed -i '/ZOOKEEPER_HOME/d' $profile
}

function zookeeper_validate
{
	if [ -z "$ZOOKEEPER_HOME" -o ! -d "$ZOOKEEPER_HOME" ]; then
		echo "not installed"
		exit 1
	fi

	cd $ZOOKEEPER_HOME || exit 1

	bin/zkCli.sh -server $master:2181 << EOF
create /zk_demo demo1
ls /
get /zk_demo
set /zk_demo demo2
get /zk_demo
delete /zk_demo
EOF
}
