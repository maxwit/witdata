#!/bin/sh

function ssh_test()
{
	for host in $@
	do
		ssh $host echo "login $host successfully!"
	done
}

opt_test=0

for opt in $@
do
	case $opt in
	-t|--test)
		opt_test=1
		;;
	*)
		echo -e "Invalid option '$opt'\n"
		exit 1
	esac
done

if [ -e .slaves ]; then
	slaves=`cat .slaves`
	hosts=(localhost $slaves)
else
	hosts=(localhost)
fi

if [ $opt_test -eq 1 ]; then
	ssh_test ${hosts[@]}
	echo
	exit 0
fi

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
	echo "Copying $kf [$count/$total]: $USER@$host ..."
	# TODO: no-interactive support
	ssh-copy-id $host

	((count++))
	echo
done

ssh_test ${hosts[@]}
echo
