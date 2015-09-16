function get_value()
{
	key=$1
	line=`grep "^${key}\s*=" .config`
	echo ${line#${key}*=}	
}

if [ -e .config ]; then
	mode="cluster"

	master=`get_value 'master'`
	# FIXME
	if [ -z "$master" ]; then
		master=`hostname`
	fi

	slaves=`get_value 'slaves'`

	user=`get_value 'user'`
	if [ -z "$user" ]; then
		user='$USER'
	fi

	hosts=($master $slaves)
else
	mode="pseudo"
	user=$USER
	hosts=(localhost)
fi
