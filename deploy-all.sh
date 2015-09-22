#!/bin/sh

cd `dirname $0`

# setup-ssh.sh
# setup-jdk.sh

for app in zk
do
	for seq in $app-destroy.sh $app-deploy.sh $app-validate.sh
	do
		echo "##################################"
		echo "    executing $seq"
		echo "##################################"
		./$seq || exit 1
		echo
	done
done
