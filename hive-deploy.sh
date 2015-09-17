#!/bin/sh

if [ "$HADOOP_HOME" == "" ]; then
	echo -e "Warning:hadoop do not installed!\n"
	exit 1
fi

if [ "$HIVE_HOME" != "" ]; then
	echo -e "Warning: previous hive already installed!\n"
fi

if [ -z "$JAVA_HOME" ]; then
	echo -e "JAVA_HOME not set!\n"
	exit 1
fi

repo='/mnt/witpub/devel/hadoop/apache-hive-1.2.1-bin.tar.gz'
hive_tarball=$repo
hive=`basename $hive_tarball`
hives=(${hive//-/ })
new_hive=${hives[1]}-${hives[2]}
old_name=${hive%%.tar.*}


cd
echo "extracting $hive ..."
tar xf $repo || exit 1
mv $old_name $new_hive

grep HIVE_HOME ~/.bashrc || cat >> ~/.bashrc <<EOF 
export HIVE_HOME=$HOME/hive-1.2.1
export PATH=$PATH:$HIVE_HOME/bin
export HIVE_CONF_DIR=$HIVE_HOME/conf
EOF
