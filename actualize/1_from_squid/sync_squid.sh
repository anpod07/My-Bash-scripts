#!/usr/local/bin/bash
# ======================================================================================== #
# Синхронизируем IP по АКЛу: из squid.conf в таблицу GZI_EMAIL
# ======================================================================================== #
# Список файлов для работы скрипта: sync_squid.bash, sync_squid.sql, актуальный squid.conf
# ======================================================================================== #
export LANG=ru_RU.UTF-8
export MM_CHARSET=UTF-8
export ORACLE_HOME=/usr/lib/oracle/10.2.0.5/client
export TNS_ADMIN=/usr/lib/oracle/10.2.0.5/client/network/admin
export LD_LIBRARY_PATH=/usr/lib/oracle/10.2.0.5/client/lib
export NLS_LANG=RUSSIAN_CIS.UTF8
fullpath="/root/scripts/actualize/1_from_squid"
src="$fullpath/sync_squid.sql"
result="$fullpath/result.dat"
# Выбираем из gzi_email данные: acl;ip
cd $fullpath
:>$result
#sqlplus u44700@proj/... <<EOF
sqlplus u44700@p9ir21/... <<EOF
 SET LINESIZE 100
 SET PAGESIZE 1500
 spool $result
 @$src
 spool off
 disconnect
 exit
EOF
grep ";" $result | grep -v '^ACL' | awk -F ";" 'gsub("      *","") {print $0}' > _01
# Выбираем из squid.conf: acl;ip
#grep ^acl squid.conf | grep "255.255.255.255" | recode -f KOI8-R..UTF-8 | awk -F "/255.255" '{print $1}' | awk '{print $2 ";" $4}' > squid
grep '^acl\|^#_#acl' squid.conf | grep "255.255.255.255" | recode -f KOI8-R..UTF-8 | awk -F "/255.255" '{print $1}' | awk '{print $2 ";" $4}' > squid
# Заменяем АКЛу IP из squid.conf. Отмечаем, если АКЛа нет в squid.conf
awk -F ";" '{{if (FILENAME == "squid") {pop[$1] = $2; next}} \
	     {if (FILENAME != "squid") \
		{if (pop[$1] == "") {print "--- " $1 " not found in squid.conf"} \
		else {print $1 ";" pop[$1]}}}}' squid _01 > _02
# Список ненайденных АКЛов для исправления вручную
grep "squid.conf" _02 | awk '{print $2}' > _not_found
# Формируем список запросов для обновления таблицы gzi_email
grep -v "squid.conf" _02 | awk -F ";" '{printf ("UPDATE gzi_email SET ip="sq$2sq" WHERE acl="sq$1sq";\n")}' sq="'" > _to_sync.sql
# Обновляем таблицу gzi_email
echo -n "Update GZI_EMAIL table? (y/n) "
read upd
if [ "$upd" = "y" ]
 then
#  sqlplus u44700@proj/... < $fullpath/_to_sync.sql
  sqlplus u44700@p9ir21/... < $fullpath/_to_sync.sql
  #sqlplus u44700@train/... < $fullpath/_to_sync.sql
  echo "Table updated successfully."
 else
  echo "Table not updated."
fi
rm $result _01 _02 squid _to_sync.sql
