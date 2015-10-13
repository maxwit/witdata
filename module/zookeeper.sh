function zookeeper_deploy
{
	sudo -u $hadoop_user mkdir -p $zk_data_dir || exit 1

	cp conf/zoo{_sample,}.cfg || return 1
	sed -i "s:^dataDir=.*:dataDir=$zk_data_dir:" conf/zoo.cfg

	if [ $mode = "cluster" ]; then
		local count=1

		for host in ${hosts[@]}
		do
			echo "server.$count=$host:2888:3888" >> conf/zoo.cfg
			((count++))
		done

		echo $((this+1))> $zk_data_dir/myid
	fi

	sed '/^#/d' conf/zoo.cfg 

	add_env ZOOKEEPER_HOME $PWD
	add_path '$ZOOKEEPER_HOME/bin'
}
