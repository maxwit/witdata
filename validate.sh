#!/bin/sh

temp=`mktemp`

$HOME/hadoop-2.7.1/bin/hadoop fs -put /$temp

ssh slave1 $HOME/hadoop-2.7.1/bin/hadoop fs -ls `basename $temp`

