function hive_deploy
{
	add_env HIVE_HOME $PWD
	add_env HIVE_CONF_DIR '$HIVE_HOME/conf'
	add_path '$HIVE_HOME/bin'

	#cp $top/service/hive /etc/init.d/ || exit 1
	#chmod +x /etc/init.d/hive
}
