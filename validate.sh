#!/bin/sh

for host in `cat .slaves`
do
	ssh $host echo "login $host successfully!"
	echo
done
