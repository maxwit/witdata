#!/bin/sh

# source ~/.bashrc

# FIXME
for str in `grep JAVA_HOME ~/.bashrc`
do
	eval $str > /dev/null
done

javac -version || exit 1

echo "JDK successfully installed to $JAVA_HOME"
