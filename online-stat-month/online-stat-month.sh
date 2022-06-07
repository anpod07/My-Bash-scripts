#!/usr/local/bin/bash
# =================================================================== #
# Сбор интернет-статистики, используя файлы /report/*.log
# =================================================================== #
# Список файлов: online-stat-month.sh, online-stat-month.sql
#		 из /report/*.log (выборочно)
# =================================================================== #
export LANG=ru_RU.UTF-8
export MM_CHARSET=UTF-8
export ORACLE_HOME=/usr/lib/oracle/10.2.0.5/client
export TNS_ADMIN=/usr/lib/oracle/10.2.0.5/client/network/admin
export LD_LIBRARY_PATH=/usr/lib/oracle/10.2.0.5/client/lib
export NLS_LANG=RUSSIAN_CIS.UTF8
#export NLS_LANG=RUSSIAN_CIS.CL8KOI8R
fullpath="/root/scripts/online-stat-month"
src="$fullpath/online-stat-month.sql"
result="$fullpath/result.dat"
cd $fullpath
:>$result
# Берем актуальный список пользователей из БД, имеющих ACL
#sqlplus u44700@p9ir21/... <<EOF
sqlplus u44700@proj/... <<EOF
 SET LINESIZE 140
 SET PAGESIZE 1500
 spool $result
 @$src
 spool off
 disconnect
 exit
EOF
# отбрасываем первые 4 строки, потом последние 4 строки, убираем лишние пробелы
sed -e '1,4d' $result | sed -e :a -e '$d;N;2,4ba' -e 'P;D' | awk -F ";" 'gsub("      *","") {print $0}' | grep -v "^;" > all
# объединяем и суммируем все месячные лог-файлы в один, также меняем длинные части строки на короткие (домены 2-3 уровня)
awk '{if ($3 ~ "safeframe.googlesyndication.com") {print $1,$2,"safeframe.googlesyndication.com",$4} \
      else {if ($3 ~ "googlevideo.com") {print $1,$2,"googlevideo.com",$4} \
            else {if ($3 ~ "video.*ttvnw.net") {print $1,$2,"ttvnw.net",$4} \
                  else {if ($3 ~ "metric.gstatic.com") {print $1,$2,"metric.gstatic.com",$4} \
                        else {print $0}}}}}' *.log |\
awk '{pop[$1";"$2";"$3]+=$4}; END {for (cc in pop) {print cc ";" pop[cc]}}' | sort -t ";" -k4rn > log
# заменяем ACL на ФИО; если нет ФИО - пишем ACL (размер в байтах)
#awk -F ";" '{{if (FILENAME == "all") {pop[$6] = $1 ";" $2 ";" $3 ";" $4 ";" $5; next}} \
#             {if (FILENAME != "all") {if (pop[$1] != "") {print pop[$1] ";" $2 ";" $3 ";" $4 " B"} \
#            			      else {print $1 ";" $2 ";" $3 ";" $4/1048576 " MB"}}}}' all log > result
# заменяем ACL на ФИО; если нет ФИО - пишем ACL (размер в мега-байтах)
awk -F ";" '{{if (FILENAME == "all") {pop[$6] = $1 ";" $2 ";" $3 ";" $4 ";" $5; next}} \
             {if (FILENAME != "all") {if (pop[$1] != "") {print pop[$1] ";" $2 ";" $3 ";" $4/1048576 " MB"} \
            			      else {print $1 ";" $2 ";" $3 ";" $4/1048576 " MB"}}}}' all log > result
rm $result log all
