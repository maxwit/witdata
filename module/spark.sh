function spark_deploy
{
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
	fi
}

function spark_destroy
{
	sed -i '/SPARK_/d' $profile
}
