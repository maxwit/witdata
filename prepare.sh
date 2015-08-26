#!/bin/sh

#dist=`lsb_release -si`
#
#case "$dist" in
#Ubuntu|Debian)
#	installer="apt-get"
#	;;
#Redhat|Fedora|CentOS|OLinux)
#	installer="yum"
#	;;
#*)
#	echo -e "'$dist' not supported!\n"
#	exit 1
#	;;
#esac
#
#if [ $UID != 0 ]; then
#	installer="sudo $installer"
#fi
#
#which ssh > /dev/null || $installer install -y ssh || exit 1
## FIXME
#which sshd > /dev/null || $installer install -y openssh-server || exit 1
#which rsync > /dev/null || $installer install -y rsync || exit 1

kt="rsa"
kf="id_$kt"

if [ ! -f ~/.ssh/${kf} ]; then
	ssh-keygen -P '' -f ~/.ssh/${kf}
fi

# FIXME
key=`cat ~/.ssh/${kf}.pub`
grep "$key" ~/.ssh/authorized_keys > /dev/null || echo "$key" >> ~/.ssh/authorized_keys

ssh localhost echo "SSH login successfully!" || echo "Fail to login localhost!"
echo
