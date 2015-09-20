#!/bin/sh --login

[ -z "$HIVE_HOME" ] && exit 0

echo "removing $HIVE_HOME ..."

if [ -d $HIVE_HOME ]; then
	rm -rf $HIVE_HOME || exit 1
fi

if [ -e /etc/redhat-release ]; then
	sh_config="$HOME/.bashrc"
else
	sh_config="$HOME/.profile"
fi

sed -i '/\<HIVE_/d' $sh_config

echo "Done."
