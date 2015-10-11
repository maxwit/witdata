function hive_deploy
{
	add_env HIVE_HOME $PWD
	add_env HIVE_CONF_DIR '$HIVE_HOME/conf'
	add_path '$HIVE_HOME/bin'
}

function hive_destroy
{
	sed -i '/HIVE_HOME/d' $profile
}
