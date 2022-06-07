#!/usr/local/bin/bash
#insert into s16 values ('1233','xfffdg','22.03.2020');

cat ./scope/*.csv > _all
grep "^1" _all | grep -v "Reservation\|Infinite" | awk -F "," 'OFS=";;" {print $1,$2,$3}' |\
awk -F " " '{print $1}' | awk -F ";;" '{printf ("INSERT INTO dns VALUES ("sq$1sq","sq$2sq","sq$3sq");\n")}' sq="'" > _03
