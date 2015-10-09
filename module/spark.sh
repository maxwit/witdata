function spark_deploy
{
	if [ -n "$SPARK_HOME" ]; then
		echo -e "spark already installed ($SPARK_HOME)!\n"
		return 0
	fi

	rm -rf $apps_root/$spark
	extract $spark
	cd $apps_root/$spark

	cp conf/spark-env.sh{.template,}
	echo >> conf/spark-env.sh
	echo "export JAVA_HOME=${JAVA_HOME}" >> conf/spark-env.sh
	echo "export SPARK_MASTER_IP=$master" >> conf/spark-env.sh

	add_env SPARK_HOME $PWD
	add_path '$SPARK_HOME/bin'

	if [ $mode = "cluster" ]; then
		for slave in ${slaves[@]}
		do
			echo $slave >> conf/slaves
		done

		for slave in ${slaves[@]}
		do
			$TOP/fast-scp $PWD $slave || return 1
			scp $profile $slave:$profile
		done
	fi
}

function spark_destroy
{
	if [ -z "$SPARK_HOME" ]; then
		echo "spark not installed!"
		return 0
	fi

	#if [ -e $SPARK_HOME/etc/spark/slaves ]; then
	#	local slaves=`cat $SPARK_HOME/etc/spark/slaves`
	#fi

	for host in ${hosts[@]}
	do
		echo "removing $SPARK_HOME @ $host"

		if [ $host = $master ]; then
			prefix=""
		else
			prefix="ssh $host "
		fi

		${prefix}rm -rf $SPARK_HOME
		${prefix}sed -i '/SPARK_/d' $profile
	done
}

function spark_start
{
	if [ -n "$SPARK_HOME" -a -d "$SPARK_HOME" ]; then
		echo "starting all ..."
		$SPARK_HOME/sbin/start-all.sh || return 1
	fi
}

function spark_stop
{
	if [ -n "$SPARK_HOME" -a -d "$SPARK_HOME" ]; then
		echo "stopping all ..."
		$SPARK_HOME/sbin/stop-all.sh || return 1
	fi
}

function spark_test
{
	if [ -z "$SPARK_HOME" -o ! -d "$SPARK_HOME" ]; then
		echo "spark not installed"
		return 1
	fi

	run-example SparkPi 10 || return 1
}
