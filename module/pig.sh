function pig_deploy
{
	add_env PIG_HOME $PWD
	add_path '$PIG_HOME/bin'
}

function pig_destroy
{
	sed -i '/PIG_HOME/d' $profile
}
