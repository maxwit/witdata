function zk_deploy
{
	if [ "$ZOOKEEPER_HOME" != "" ]; then
		echo -e "ZooKeeper already installed!\n"
		exit 1
	fi

	extract $zk

	cd $HOME/$zk

	update_export ZOOKEEPER_HOME \$HOME/$zk

	cp -v conf/zoo{_sample,}.cfg || exit 1
	bin/zkServer.sh start || exit 1
}

function zk_destroy
{
	[ -z "$ZOOKEEPER_HOME" ] && exit 0

	if [ -d "$ZOOKEEPER_HOME" ]; then
		zk=`basename $ZOOKEEPER_HOME`
		echo "stoping $zk ..."
		cd $ZOOKEEPER_HOME
		bin/zkServer.sh stop || exit 1
		echo "removing $zk ..."
		rm -rf $ZOOKEEPER_HOME || exit 1
	fi

	del_export ZOOKEEPER_HOME
}

function zk_validate
{
	if [ -z "$ZOOKEEPER_HOME" ]; then
		echo "not installed"
		exit 1
	else
		echo "$ZOOKEEPER_HOME"
	fi
	echo

	cd $ZOOKEEPER_HOME || exit 1

	bin/zkCli.sh -server 127.0.0.1:2181 << EOF
create /zk_demo demo1
ls /
get /zk_demo
set /zk_demo demo2
get /zk_demo
delete /zk_demo
EOF
}
