#!/bin/sh

cd `dirname $0`
TOP=$PWD

function ssh_setup
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

if [ -e ./.config ]; then
	. ./.config
fi

if [ -n "$config_master" ]; then
	master=$config_master
else
	master=`hostname` # FIXME
fi

slaves=($config_slaves)
hosts=($master $config_slaves)

if [ ${#hosts[@]} -ne 1 ]; then
	mode="cluster"
else
	mode="pseudo"
fi

if [ -n "$config_user" ]; then
	user=$config_user
else
	user=$USER
fi

if [ -n "$config_repo" ]; then
	repo="$config_repo"
else
	repo='/mnt/witpub/cloud/hadoop/'
fi

# FIXME: only for hbase and zk
if [ -n "$config_data_root" ]; then
	data_root="$config_data_root"
else
	data_root="$HOME/data"
fi

apps=""

if [ -n "$config_hadoop" ]; then
	hadoop=$config_hadoop
	apps="hadoop"
fi

if [ -n "$config_hive" ]; then
	hive=$config_hive
	apps="$apps hive"
fi

if [ -n "$config_zk" ]; then
	zk=$config_zk
	apps="$apps zookeeper"
fi

if [ -n "$config_hbase" ]; then
	hbase=$config_hbase
	apps="$apps hbase"
fi

if [ $init -eq 1 ]; then
	ssh_setup
	exit $?
fi

if [ -z "$JAVA_HOME" ]; then
	echo -e "JAVA_HOME not set!\n"
	exit 1
fi

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
	if [ -n "$2" ]; then
		dir=$2
	else
		dir=$HOME
	fi

	echo -n "extracting $pkg ... "
	tar xf $repo/${pkg}.tar.gz -C $dir || {
		echo "failed"
		exit 1
	}
	echo "done"
}

function execute
{
	func=$1

	echo "#########################################"
	echo "  executing $func() ..."
	echo "#########################################"

	$func
	if [ $? -ne 0 ]; then
		echo "fail to run $func!"
		exit 1
	fi

	echo
}

for app in $apps
do
	if [ ! -e ./$app.sh ]; then
		echo "$app.sh does not exists!"
		exit 1
	fi

	. ./$app.sh

	if [ $destroy -eq 0 ]; then
		for host in ${hosts[@]}
		do
			ssh $user@$host << EOF
mkdir -p $data_root
EOF
			echo
		done

		execute ${app}_deploy
		cd $TOP
		execute ${app}_validate
		cd $TOP
	else
		for host in ${hosts[@]}
		do
			ssh $user@$host << EOF
rm -rf $data_root
EOF
			echo
		done
		execute ${app}_destroy
		cd $TOP
	fi

	echo
done
