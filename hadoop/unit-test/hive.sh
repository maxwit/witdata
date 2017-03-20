temp=`mktemp`

cat > $temp << EOF
master=node1.jerry
slave1=node2.jerry
slave2=node3.jerry
EOF

hive << EOF
create table if not exists test (name string,value string)
row format delimited
fields terminated by '=';
load data local inpath '$temp'
overwrite into table test;
select * from test;
drop table test;
exit; 
EOF

rm $temp
