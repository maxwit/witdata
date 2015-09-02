#!/bin/sh

kt="rsa"
kf="id_$kt"

if [ ! -f ~/.ssh/${kf} ]; then
	ssh-keygen -P '' -f ~/.ssh/${kf}
fi

key=`cat ~/.ssh/${kf}.pub`
grep "$key" ~/.ssh/authorized_keys > /dev/null 2>&1|| echo "$key" >> ~/.ssh/authorized_keys

if [ -e .slaves ]; then
	hosts=`cat .slaves`
fi

for host in $hosts
do
	echo "copying id to $host ..."
	# TODO: no-interactive support
	ssh-copy-id $host
	echo
done

for host in localhost $hosts
do
	ssh $host echo "login $host successfully!"
done
echo
