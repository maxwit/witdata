#!/bin/sh

if [ $# = 0 ]; then
	host=localhost
else
	host=$1
fi

kt="rsa"
kf="id_$kt"

if [ ! -f ~/.ssh/${kf} ]; then
	ssh-keygen -P '' -f ~/.ssh/${kf}
fi

if [ $host = localhost ]; then
	# FIXME
	key=`cat ~/.ssh/${kf}.pub`
	grep "$key" ~/.ssh/authorized_keys > /dev/null || echo "$key" >> ~/.ssh/authorized_keys
else
	# FIXME
	key=`cat ~/.ssh/${kf}.pub`
	ssh-copy-id $host
fi

ssh $host echo "login $host successfully!" || echo "Fail to login $host!"
echo
