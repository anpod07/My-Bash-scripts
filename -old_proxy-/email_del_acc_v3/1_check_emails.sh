#!/usr/local/bin/bash
#-----------------------------------------------------------------------------------#
# ежесуточная проверка неиспользуемых email-ов за последние полгода (182 дня)       #
# в файл 'except' пишем адреса, которые будем игнорировать (системные, qpopper/TLS) #
#-----------------------------------------------------------------------------------#
wdir="/usr/home/ivan/online/email_del_acc_v3"
cd $wdir
# формируем список имен ящиков из /usr/var/mail/
cd /usr/var/mail && ls [a-z]* > $wdir/_01 && cd $wdir
# берем описание ящиков из /etc/master.passwd, если записей в master.passwd нет - пишем NO_DESCRIBTION
awk -F: '{if (FILENAME != "_01") {pop[$1] = $8; next} \
if (FILENAME == "_01" && pop[$1] != "") {printf "%-18s\t%s\n", $1, pop[$1]} \
if (FILENAME == "_01" && pop[$1] == "") {printf "%-18s\tNO_DESCRIBTION\n", $1}}' /etc/master.passwd _01 | sort > _result
rm _01
# исключаем записи из финального результа по файлу except
arrex=(`cat except`)
i=0
for i in "${arrex[@]}"; do
 exacl=`grep "^$i\>" _result | awk '{print $1}'`
 if [ "$exacl" = "$i" ]; then
  echo "Exception ACL: ($exacl)"
  grep -v "^$i\>" _result > _02
  cat _02 > _result
 fi
done
rm _02

# создаем массив имен ящиков
arr=(`awk '{print $1}' _result`)
#arr=(a-tube adonskaya crb-oon)
#printf "%s\n" "${arr[@]}"
#printf "%s\n" "${arr[*]}"

# проверяем, принимал ли аккаунт почту хотя бы раз за период в 6 месяцев из файлов /var/log/messages.*.gz
# проверяем, отправлял ли аккаунт почту хотя бы раз за период в 6 месяцев из файлов /var/log/maillog.*.gz
cd /var/log && arrmess=(`ls -tr messages*gz`)		# создаем массив имен messages-логов, от 180-го до 0-го, от старого к новому
arrmail=(`ls -tr maillog*gz`) && cd $wdir		# создаем массив имен maillog-логов, от 180-го до 0-го, от старого к новому
:>_mess; i=0; j=0
for i in "${arr[@]}"; do	# поиск по аклу
 echo "Checking $i in messages ..."
 for j in "${arrmess[@]}"; do
  res=`zgrep -m1 " $i " /var/log/$j`
  if [ -n "$res" ]; then	# если найдена запись, что акк забирал почту, - прекращаем поиск и переходим к следующему акку
   printf "%-85s\tACTIVE\n" "`grep "^$i " _result`" >> _mess
   break
  fi
 done
 if [ -z "$res" ]; then		# если записей не обнаружено ни в одном из 180-ти файлов messages, ищем в maillog-ах записи об отправленных письмах
  echo "Checking $i in maillog ..."
  for j in "${arrmail[@]}"; do
   res=`zgrep -m1 "from=<$i@nkmz" /var/log/$j`
   if [ -n "$res" ]; then	# если найдена запись, что акк отправлял почту, - прекращаем поиск и переходим к следующему акку
    printf "%-85s\tACTIVE_out\n" "`grep "^$i " _result`" >> _mess
    break
   fi
  done
 fi
 if [ -z "$res" ]; then		# если записей не обнаружено ни в одном из файлов messages и maillog, то отмечаем акл как неактивный (DELETE_IT)
  echo "DELETE $i"
  printf "%-85s\tDELETE_IT\n" "`grep "^$i " _result`" >> _mess
 fi
done

# формируем архивный лог списка акков, которые можно удалять
grep "DELETE_IT" _mess > ./mess_bd/_mess_delete_`date +%Y_%m_%d`
rm _result
