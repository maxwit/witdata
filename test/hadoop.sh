temp=`mktemp`
date > $temp

echo "putting $temp to master ..."
hadoop fs -put $temp /tmp/ || return 1
echo

for slave in `cat $HADOOP_HOME/etc/hadoop/slaves`
do
	echo "checking '$slave' ..."
	ssh $slave hadoop fs -ls $temp || return 1
done
echo

echo "removing $temp ..."
hadoop fs -rm $temp || return 1
echo

rm $temp
