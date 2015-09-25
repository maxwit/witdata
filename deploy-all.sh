#!/bin/sh

cd `dirname $0`
TOP=$PWD

function ssh_setup()
{
	kt="rsa"
	kf="id_$kt"

	if [ ! -f ~/.ssh/${kf} ]; then
		ssh-keygen -P '' -f ~/.ssh/${kf}
	fi

	#key=`cat ~/.ssh/${kf}.pub`
	#grep "$key" ~/.ssh/authorized_keys > /dev/null 2>&1|| echo "$key" >> ~/.ssh/authorized_keys

	total=${#hosts[@]}
	count=1

	for host in ${hosts[@]}
	do
		echo "Copying $kf [$count/$total]: $user@$host ..."
		# TODO: no-interactive support
		ssh-copy-id $user@$host

		((count++))
		echo
	done

	for host in ${hosts[@]}
	do
		ssh $user@$host echo "login $host successfully!"
	done
	echo
}

destroy=0
init=0

while [ $# -gt 0 ]
do
	case $1 in
	-i|--init)
		init=1
		;;
	-d|--dir)
		destroy=1
		;;
	*)
		echo "usage: `basename $0 [-d|--dir] [-i|--init]`"
		exit 1
	esac

	shift
done

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

if [ $init -eq 1 ]; then
	ssh_setup
	exit $?
fi

if [ -z "$JAVA_HOME" ]; then
	echo -e "JAVA_HOME not set!\n"
	exit 1
fi

# FIXME
repo='/mnt/witpub/cloud/hadoop/'

hadoop='hadoop-2.7.1'
hive='apache-hive-1.2.1-bin'
zk='zookeeper-3.4.6'

if [ -e /etc/redhat-release ]; then
	profile="$HOME/.bash_profile"
else
	profile="$HOME/.profile"
fi

function update_export
{
	key=$1
	val=$2

	grep $key $profile > /dev/null
	if [ $? -eq 0 ]; then
		sed -i "s:$key=.*:$key=$val:" $profile
	else
		echo "export $key=$val" >> $profile
	fi

	eval export $key=$val
}

function del_export
{
	key=$1

	sed -i "/export $key/d" $profile
	unset $key
}

function add_path
{
	path=$1

	# FIXME
	grep "PATH=.*$path" $profile > /dev/null
	if [ $? -ne 0 ]; then
		echo "export PATH=\$PATH:$path" >> $profile
		eval export PATH=\$PATH:$path
	fi
}

function del_path
{
	path=$1
}

function extract
{
	pkg=$1
	echo "extracting $pkg ..."
	tar xf $repo/${pkg}.tar.gz -C $HOME || {
		echo "extract failed!"
		exit 1
	}
}

function execute
{
	func=$1
	echo "#########################################"
	echo "  executing $func() ..."
	echo "#########################################"
	$func
	echo
}

for app in hadoop zk
do
	if [ ! -e ./$app.sh ]; then
		echo "$app.sh does not exists!"
		exit 1
	fi

	. ./$app.sh

	if [ $destroy -eq 0 ]; then
		execute ${app}_deploy || exit 1
		cd $TOP
		execute ${app}_validate || exit 1
		cd $TOP
	else
		execute ${app}_destroy || exit 1
		cd $TOP
	fi

	echo
done
