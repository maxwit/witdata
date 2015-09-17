#!/bin/sh

while [ $# -gt 0 ]
do
	case $1 in
	-m|--master)
		master=$2;
		shift
		;;
	-u|--user)
		user=$2;
		shift
		;;
	*)
		echo "unknown option '$1'!"
		exit 1
	esac

	shift
done

if [ -z "$master" ]; then
	# TODO: guess with .config
	echo "usage: `basename $0` [-u|--user user] <-m|--master host>"
	exit 1
fi

[ -z "$user" ] && user=$USER

wd=`basename $PWD`

echo -n "copying $wd to $user@$master .."
ssh $user@$master rm -rf $wd
echo '.'
if [ -d .git ]; then
	temp=`mktemp -d`
	cp -r $PWD $temp
	rm -rf $temp/$wd/.git*
	scp -r $temp/$wd $user@$master:
else
	scp -r $PWD $user@$master:
fi
echo

# setup-ssh.sh
# setup-jdk.sh
for seq in hadoop-destroy.sh hadoop-deploy.sh hadoop-validate.sh
do
	echo "executing $seq ..."
	ssh $user@$master $wd/$seq || exit 1
	echo
done
