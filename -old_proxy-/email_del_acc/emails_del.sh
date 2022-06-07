#!/usr/local/bin/bash
#---------------------------------------------#
# список неиспользуемых email-ов до 2019 года #
#---------------------------------------------#
# формируем список имен ящиков в /var/mail/ по дате, выбираем старше 2019 года
ls -ltr /var/mail/ | awk '$9 !~ /^\./ && $8 ~ /201[0-8]/ && $9 !~ /\.sh/ {print $9 ":" $8}' > _01
# берем описание ящиков из /etc/master.passwd, если записей в master.passwd нет - пишем NO_DESCRIBTION
awk -F: '{if (FILENAME != "_01") {pop[$1] = $8; next} \
if (FILENAME == "_01" && pop[$1] != "") {printf "%-18s\t%4s\t%s\n", $1, $2, pop[$1]} \
if (FILENAME == "_01" && pop[$1] == "") {printf "%-18s\t%4s\tNO_DESCRIBTION\n", $1, $2}}' /etc/master.passwd _01 | sort > _result
cp _result _result_full				# результат без применения исключений из файла except
rm _01
# исключаем записи из финального результа по файлу except
arrex=(`cat except`)
i=0
while [ -n "${arrex[i]}" ]
do
 exacl=`grep "^${arrex[i]}\>" _result | awk '{print $1}'`
# echo "arrex[$i]: " ${arrex[i]}
# echo "exacl: " $exacl
 if [ "$exacl" = "${arrex[i]}" ]
  then
   echo "Exception ACL: ($exacl)"
   grep -v "^${arrex[i]}\>" _result > _02
#   sleep 1
   cat _02 > _result
 fi
 (( i++ ))
done
rm _02
# создаем массив имен ящиков
arr=(`awk '{print $1}' _result`)
#arr=(test01 test02 test03)
# проверяем, кто и когда обращался за почтой за 6 месяцев из файлов /var/log/messages.*.gz
#while [ -n "${arr[i]}" ]			# WARNING!!! процесс ресурсоемкий и длительный
#do
# echo "Checking ${arr[i]} ..."
## zcat /var/log/messages.*.gz | grep " ${arr[i]} " >> _mess		# искать за последние 180 дней (6 месяцев)
## zcat /var/log/messages.???.gz | grep " ${arr[i]} " >> _mess		# искать со 100 до 180 дней
## zcat /var/log/messages.??.gz | grep " ${arr[i]} " >> _mess		# искать со 10 до 99 дней
# zcat /var/log/messages.?.gz | grep " ${arr[i]} " >> _mess		# искать за последние 10 дней
# (( i++ ))
#done
# меню
while [ "$inp" != "y" -a "$inp" != "n" ]
do
 echo "Do you want to delete all email accaunts?"
 echo -n "Delete(y), Cancel(n), View accaunt list(v): "
 read inp
 case $inp in
  "y" )
      i=0
      while [ -n "${arr[i]}" ]
      do
       echo "Deleting ${arr[i]} ..."
       echo -e "y\ny\n" | rmuser ${arr[i]}	# WARNING!!! автоматически удаляем пользователей ящиков из массива
       (( i++ ))
      done
      ;;
  "n" ) echo "Exit" ;;
  "v" ) echo ${arr[*]} ;;
  * ) echo "You enter some shit. Repeat" ;;
 esac
done
