function spark_deploy
{
	cp conf/spark-env.sh{.template,}
	echo >> conf/spark-env.sh
	echo 'export SPARK_LOG_DIR=/var/log/$USER/spark' >> conf/spark-env.sh
	echo "export JAVA_HOME=${home_dict[java]}" >> conf/spark-env.sh
	echo "export SPARK_MASTER_IP=$master" >> conf/spark-env.sh

	sed -e '/^#/d' -e '/^$/d' conf/spark-env.sh

	add_env SPARK_HOME $PWD
	add_path '$SPARK_HOME/bin'

	if [ $mode = "cluster" ]; then
		for slave in ${slaves[@]}
		do
			echo $slave >> conf/slaves
		done
	fi
}
