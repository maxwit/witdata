zkCli.sh -server localhost:2181 << EOF
create /zk_demo demo1
ls /
get /zk_demo
set /zk_demo demo2
get /zk_demo
delete /zk_demo
EOF
