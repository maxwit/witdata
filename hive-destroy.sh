#!/bin/sh --login

[ -z "$HIVE_HOME" ] && exit 0

echo "removing $HIVE_HOME ..."

if [ -d $HIVE_HOME ]; then
	rm -rf $HIVE_HOME || exit 1
fi

sed -i '/export HIVE_HOME/d' ~/.bashrc

echo "Done."
