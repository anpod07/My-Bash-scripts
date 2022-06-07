#!/usr/local/bin/bash
export LANG=ru_RU.UTF-8
export MM_CHARSET=UTF-8
export ORACLE_HOME=/usr/lib/oracle/10.2.0.5/client
export TNS_ADMIN=/usr/lib/oracle/10.2.0.5/client/network/admin
export LD_LIBRARY_PATH=/usr/lib/oracle/10.2.0.5/client/lib
export NLS_LANG=AMERICAN_CIS.CL8MSWIN1251

#sqlplus u44700@proj/... <<EOF
sqlplus u44700@p9ir21/... <<EOF
 CREATE TABLE s16 (ip VARCHAR2(15 BYTE), pk VARCHAR2(38 BYTE), d_exp DATE);
 LOAD DATA INFILE '/root/scripts/oracle_csv/_01' INTO TABLE s16 FIELDS TERMINATED BY ';;' LINES TERMINATED BY '\n';
 disconnect
 exit
EOF

#load data local infile '/root/sqlplus_to_mysql/_001' into table kadry fields terminated by ';_;' lines terminated by '\n';
#LOAD DATA INFILE 'data.txt' INTO TABLE table2 FIELDS TERMINATED BY ',';
