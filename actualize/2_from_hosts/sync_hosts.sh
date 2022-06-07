#!/usr/local/bin/bash
# =================================================================================== #
# Синхронизируем IP по почтовому ящику: из hosts в таблицу GZI_EMAIL
# =================================================================================== #
# Список файлов для работы скрипта: sync_hosts.bash, sync_hosts.sql, актуальный hosts
# =================================================================================== #
export LANG=ru_RU.UTF-8
export MM_CHARSET=UTF-8
export ORACLE_HOME=/usr/lib/oracle/10.2.0.5/client
export TNS_ADMIN=/usr/lib/oracle/10.2.0.5/client/network/admin
export LD_LIBRARY_PATH=/usr/lib/oracle/10.2.0.5/client/lib
export NLS_LANG=RUSSIAN_CIS.UTF8
fullpath="/root/scripts/actualize/2_from_hosts"
src="$fullpath/sync_hosts.sql"
result="$fullpath/result.dat"
# Выбираем из gzi_email данные: email;ip
cd $fullpath
:>$result
#sqlplus u44700@proj/... <<EOF
sqlplus u44700@p9ir21/... <<EOF
 SET LINESIZE 400
 SET PAGESIZE 1500
 spool $result
 @$src
 spool off
 disconnect
 exit
EOF
grep ";" $result | grep -v '^EMAIL' | awk -F ";" 'gsub("      *","") {print $0}' > _base
# Проверка на дубликаты почтовых аккаунтов в GZI_EMAIL
##awk -F ";" '{print $1}' _base | sort | uniq -d
# Выбираем из hosts: email;ip
grep -v "#service\|#nouser" hosts | awk -F ".nkmz.donetsk" '{print $1}' | awk '{print $2 ";" $1}' > _host
# Формируем список почтовых акк-ов, которых нет в hosts, и правим их вручную (кроме Влада -мать его- Трунова)
awk -F ";" '{{if (FILENAME == "_host") {pop[$1] = $2; next}} \
	     {if (FILENAME != "_host") \
		{if (pop[$1] == "") {print "--- " $1 ";" $2} \
		else {print $1 ";" pop[$1]}}}}' _host _base | grep '^-' | grep -v "vlad.trunov" > _check
# Запускаем: search_active_email.bash
#
#			 БД	     hosts
#                    -----------     ------
#                    |     |   |     |    |
# Приводим к виду: почта; ip; акл; почта; ip
# Не учитываем WEB и XXX (только BAT), т.е. тех, для кого pop[$1] будет пустым (не берем из БД)
awk -F ";" '{{if (FILENAME == "_base") {pop[$1] = $1 ";" $2 ";" $3; next}} \
	     {if (FILENAME != "_base" && pop[$1] != "") {print pop[$1] ";" $1 ";" $2}}}' _base _host |\
awk -F ";" '{if ($3=="" || ($3!="" && $2==$5)) {print $1 ";" $5} \
             else {print "- " $0}}' > _02
# Формируем список запросов для обновления таблицы GZI_EMAIL
grep -v '^-' _02 | awk -F ";" '{printf ("UPDATE gzi_email SET ip="sq$2sq" WHERE email="sq$1sq";\n")}' sq="'" > _to_sync.sql
# Получаем список тех, у кого НЕ СОВПАДАЮТ ip из squid.conf (из синхронизированной БД) и hosts
grep '^-' _02 > zzz
# ================================================================================ #
# Активность почтовых аккаунтов пользователей, имеющих разные IP для инета и почты
# Перед запуском скрипта нужно:
#       - создать директории ./mess
#       - скопировать файлы: /var/log/messages* -> ./mess/
# Результате работы скрипта: _not_found
# ================================================================================ #
arr=(`awk '{print $2}' zzz`)		# Создаем массив почтовых аклов
i=0; j=0; ct=0				# ct - порядковый номер архивного файла messages.*.gz
echo "== messages =="
# Выполняем поиск активных аклов по messages. Если что-то найдено, генерим строку для добавления в БД
while [ -n "${arr[i]}" ]
do
 ac=`echo ${arr[i]} | awk -F ";" '{print $4}'`
 if [ -n "`grep " $ac " ./mess/messages`" ]
  then
   echo ${arr[i]} | awk -F ";" '{printf ("UPDATE gzi_email SET ip="sq$5sq" WHERE email="sq$4sq";\n")}' sq="'" >> _to_sync.sql
  else
   arr2=( "${arr2[@]}" "${arr[i]}" )	# Массив аклов, не обнаруженных в messages. По нему делаем дальнейший поиск
   (( j++ ))				# Считаем количество оставшихся ненайденных (неактивных) аклов
 fi
 (( i++ ))
done
echo "__ $j records left __"
while [ $ct -le 180 ]			# Выполняем цикл messages.*.gz, с 0 до 180 файла
do
 i=0; j=0
 echo "== messages.$ct.gz =="
# Если номер архивного файла четный, работаем с массивом arr2. Оставшиеся аклы пишем в массив arr
 if [ $(($ct % 2 )) -eq 0 ]
  then
   arr=()				# очищаем массив для его последующего наполнения
   while [ -n "${arr2[i]}" ]
   do
    ac=`echo ${arr2[i]} | awk -F ";" '{print $4}'`
    if [ -n "`zgrep " $ac " ./mess/messages.$ct.gz`" ]
     then
      echo ${arr2[i]} | awk -F ";" '{printf ("UPDATE gzi_email SET ip="sq$5sq" WHERE email="sq$4sq";\n")}' sq="'" >> _to_sync.sql
     else
      arr=( "${arr[@]}" "${arr2[i]}" )	# Массив аклов, не обнаруженных в messages.*.gz. По нему делаем дальнейший поиск
      (( j++ ))				# Считаем количество оставшихся ненайденных (неактивных) аклов
    fi
    (( i++ ))
   done
   echo "__ $j records left __"
# Если номер архивного файла нечетный, работаем с массивом arr. Оставшиеся аклы пишем в массив arr2
  else
   arr2=()				# очищаем массив для его последующего наполнения
   while [ -n "${arr[i]}" ]
   do
    ac=`echo ${arr[i]} | awk -F ";" '{print $4}'`
    if [ -n "`zgrep " $ac " ./mess/messages.$ct.gz`" ]
     then
      echo ${arr[i]} | awk -F ";" '{printf ("UPDATE gzi_email SET ip="sq$5sq" WHERE email="sq$4sq";\n")}' sq="'" >> _to_sync.sql
     else
      arr2=( "${arr2[@]}" "${arr[i]}" )	# Массив аклов, не обнаруженных в messages.*.gz. По нему делаем дальнейший поиск
      (( j++ ))				# Считаем количество оставшихся ненайденных (неактивных) аклов
    fi
    (( i++ ))
   done
   echo "__ $j records left __"
 fi
 (( ct++ ))
done
i=0; :>_not_found
# Т.к. последний номер файла - четный (180), работаем с массивом arr. Переносим содержимое массива arr в файл
while [ -n "${arr[i]}" ]
do
 echo ${arr[i]} >> _not_found
 (( i++ ))
done
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
rm $result _base _02 _host _to_sync.sql zzz
