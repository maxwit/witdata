function get_value()
{
	key=$1
	line=`grep "^${key}\s*=" .config`
	echo ${line#${key}*=}	
}

if [ -e .config ]; then
	mode="cluster"

	master=`get_value 'master'`
	slaves=`get_value 'slaves'`

	hosts=($master $slaves)
else
	mode="pseudo"

	hosts=(localhost)
fi
