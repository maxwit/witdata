function zookeeper_deploy
{
	local data_dir=$data_root/zookeeper

	mkdir -p $data_dir || return 1

	cp -v conf/zoo{_sample,}.cfg || return 1
	sed -i "s:^dataDir=.*:dataDir=$data_dir:" conf/zoo.cfg

	if [ $mode = "cluster" ]; then
		local count=1

		for host in ${hosts[@]}
		do
			echo "server.$count=$host:2888:3888" >> conf/zoo.cfg
			((count++))
		done

		echo $myid > $data_dir/myid
	fi

	sed '/^#/d' conf/zoo.cfg 

	add_env ZOOKEEPER_HOME $PWD
	add_path '$ZOOKEEPER_HOME/bin'
}

function zookeeper_destroy
{
	sed -i '/ZOOKEEPER_HOME/d' $profile
}
