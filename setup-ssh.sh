#!/bin/sh

kt="rsa"
kf="id_$kt"

if [ ! -f ~/.ssh/${kf} ]; then
	ssh-keygen -P '' -f ~/.ssh/${kf}
fi

slaves=(`cat .slaves`)
if [ ${#slaves[@]} = 0 ]; then
	echo -e "none slave defined!\n"
	exit 1
fi

for slave in ${slaves[@]}
do
	# FIXME
	echo "copying id to $slave ..."
	ssh-copy-id $slave
	echo
done

for slave in ${slaves[@]}
do
	ssh $slave echo "login $slave successfully!"
done
echo
