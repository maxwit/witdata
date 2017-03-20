function pig_deploy
{
	echo "export JAVA_HOME=${home_dict[java]}" > conf/pig-env.sh
	add_env PIG_HOME $PWD
	add_path '$PIG_HOME/bin'
}
