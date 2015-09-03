#!/bin/bash --login

env
javac -version || exit 1

echo "JDK successfully installed to $JAVA_HOME"
