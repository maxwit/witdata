#!/bin/sh

dist=`lsb_release -si`

case "$dist" in
Ubuntu|Debian)
	installer="apt-get"
	;;
Redhat|Fedora|CentOS|OLinux)
	installer="yum"
	;;
*)
	echo -e "'$dist' not supported!\n"
	exit 1
	;;
esac

if [ $UID != 0 ]; then
	installer="sudo $installer"
fi

which ssh > /dev/null || $installer install -y ssh || exit 1
# FIXME
which sshd > /dev/null || $installer install -y openssh-server || exit 1
which rsync > /dev/null || $installer install -y rsync || exit 1

kt="rsa"
key="id_$kt"

if [ ! -f ~/.ssh/${key} ]; then
	ssh-keygen -P '' -f ~/.ssh/${key}
fi
# FIXME
#if [ ! -f ~/.ssh/authorized_keys ]; then
  	cp ~/.ssh/${key}.pub ~/.ssh/authorized_keys
#fi

#export HADOOP\_PREFIX=/usr/local/hadoop

ssh localhost echo "SSH login successfully!" || echo "Fail to login localhost!"
echo
