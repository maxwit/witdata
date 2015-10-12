temp=`mktemp`

cat > $temp << EOF
master  node1.jerry
slave1  node2.jerry
slave2  node3.jerry
EOF
	
hdfs dfs -put $temp /tmp

pig << EOF
test = load '$temp' as (slaves:chararray, domain:chararray);
describe test;
dump test;
\q
EOF

rm $temp
