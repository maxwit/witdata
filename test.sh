#!/bin/sh

for host in `cat .hosts`
do
	ssh $host echo "login $host successfully!"
done
