#!/bin/sh

cp .config $user@$master:config.txt
ssh $user@$master hive <<EOF
create table if not exists test (name string,value string)
row format delimited
fields terminated by '=';
load data local inpath '/home/$user/config.txt'
overwrite into table test;
select * from test;
drop table test;
exit; 
EOF
