function get_value()
{
	key=$1
	line=`grep "^${key}\s*=" .config`
	echo ${line#${key}*=}	
}

if [ -e .config ]; then
	master=`get_value 'master'`
	slaves=`get_value 'slaves'`
	user=`get_value 'user'`
fi

if [ -z "$user" ]; then
	user="$USER"
fi

if [ -z "$master" ]; then
	# FIXME
	master=`hostname`
fi

hosts=($master $slaves)

# FIXME
hadoop='hadoop-2.7.1'

