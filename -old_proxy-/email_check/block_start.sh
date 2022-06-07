#!/usr/local/bin/bash
#-------------------------------------------------------------------------------------------------#
# скрипт проверяет количество запросов от определенного почтового ACL-а по /var/log/messages	  #
# высчитывается среднее значение кол-ва обращений к серверу в секундах, сравнивается с допустимым #
# при положительном результате высылается уведомление по email для каждого из нарушителей	  #
# имеется возможность автоматической блокировки почтового ACL-а средствами IPFW			  #
# рекомендуемое время запуска скрипта: ночью, 1 раз в сутки, в 23.50-23.55			  #
#-------------------------------------------------------------------------------------------------#
cd /usr/home/ivan/online/email_check					# переход в папку со скриптами (для закуска из /etc/crontab)
#dat=`date "+%Y-%m-%d %T"`						# сегодняшняя дата
dat=`date "+%d.%m.%Y"`							# сегодняшняя дата
reco="/usr/local/bin/recode -f KOI8-R..CP1251"				# перекодировщик текста письма для пользователя
cp /var/log/messages messages						# живой файл не берем, т.к. он постоянно дополняется
mesf=messages								# путь к файлу messages (/var/log/messages)
datlog=`stat -f "%Sm" -t "%Y-%m-%d" $mesf`				# дата модификации файла messages, для имени log-файла
excf=except								# файл с исключениями для ACL-ов и IP-адрессов
logf=`echo block_$datlog`						# файл отчета работы скрипта
chkl=30									# мин. число обращений к серверу в сутки (по умолчанию = 10)
chkm=144								# допустимое число обращений к серверу в сутки (144 = 1 раз в 10 минут)
chkh=720								# макс. число обращений к серверу в сутки (1440 = 1 раз в минуту)
chks=120								# минимальное разрешенное обращение к серверу в секунду
i=0									# счетчик для массива arr[]
#-----------------------------------------------------------------------#
funk ()									# функция для проверки ACL-ов из массива arr[]
{
 acl=$1									# имя почтового ящика, берется из массива arr[]
 aclrep=$acl@nkmz.donetsk.ua						# имя почтового ящика для письма пользователя
 addr=`grep " Stats: $acl " $mesf | awk '{print $13}' | sort -u`	# все ip-адресса, которые берут почту с ACL-а
# не проверять ACL-ы или IP-шки из файла исключений except
 exacl=`grep -e ^$acl$ $excf`
 exaddr=`grep -e ^$addr$ $excf`						# не сработает, если addr содержит более одного IP
 if [ "$exacl" = "$acl" -o "$exaddr" = "$addr" ]
  then
   echo "Exception ACL ($exacl) or IP ($exaddr). Abort checking."
#   echo -e $dat'\t'"EXCEPT"'\t'$acl'\t'"acl:$exacl addr:$exaddr"'\t'$addr >> ./logs/$logf.log
   printf "%-12sEXCEPT  %-18s except:%-18s  " $dat $acl $exacl$exaddr >> ./logs/$logf.log
   printf "%-16s" $addr >> ./logs/$logf.log
   printf "\n" >> ./logs/$logf.log
   return 1
 fi
 lines=`grep " Stats: $acl " $mesf | wc -l | awk '{print $1}'`		# сичтаем количество строк/обращений к серверу
# генерация письма пользователю для DDOS
 ddsub=`echo "Система Защиты Почтового Сервера НКМЗ: $aclrep; $dat" | $reco`
 ddtext=`echo -e "$dat с вашего почтового адреса $aclrep зафиксировано неприемлимое суточное число обращений ($lines) к почтовому серверу НКМЗ."'\n' \
 "Необходимо установить частоту обращений к серверу не чаще 1 раза в 5 минут."'\n' \
 "В противном случае возможность использования почтового адреса $aclrep будет приостановленна Системой Защиты Почтового Сервера НКМЗ."'\n\n' \
 "---"'\n'"Администратор электронной почты НКМЗ, т.63-19, 61-65" | $reco`
 if [ $lines -le $chkl ]						# если $lines < $chkl - прекращаем проверку
  then
   echo "$acl : Количество запросов к серверу $lines <= $chkl, очень редко принимает почту - неопасен"
#   echo -e $dat'\t'"RARE"'\t'$acl'\t'"pings:$lines<=$chkl"'\t'$addr >> ./logs/$logf.log
   printf "%-12sRARE    %-18s pings:$lines<=$chkl\t " $dat $acl >> ./logs/$logf.log
   printf "%-16s" $addr >> ./logs/$logf.log
   printf "\n" >> ./logs/$logf.log
   return 1
 fi
 echo "$acl : Количество обращений к серверу $lines при допустимом $chkh"
 if [ $lines -gt $chkh ]						# если $lines > $chkh - лочим сразу
  then
   echo "Come get some, asshole: " $acl, $addr
   #/sbin/ipfw -q add 2000 deny ip from $addr to 10.101.2.2 25,110,119,465,995 setup
#   echo -e $dat'\t'"DDOS"'\t'$acl'\t'"pings:$lines>$chkh"'\t'$addr >> ./logs/$logf.log
   printf "%-12sDDOS    %-18s pings:$lines>$chkh\t " $dat $acl >> ./logs/$logf.log
   printf "%-16s" $addr >> ./logs/$logf.log
   printf "\n" >> ./logs/$logf.log
   echo $ddtext | mail -s "$ddsub" $acl					# отправка письма пользователю
   return 1
 fi
 echo "$acl : Calculating timestamp date..."				# продолжаем выполнение скрипта
 arrt=(`grep " Stats: $acl " $mesf | awk '{print $3}' | sort -r`)	# создаем массив значений времени в timestamp-формате
 t=0									# обнуляем счетчик для массива arrt[]
 while [ -n "${arrt[t]}" ]
 do
  echo `date -j -f %T ${arrt[t]} +%s` >> _02				# преобразовываем время в timestamp-формат
  (( t+=1 ))
 done
# от первого числа отнимаем второе, от второго - третье и т.д.; разницу - суммируем (sum)
 summ=`cat _02 | awk 'BEGIN {num=0; sum=0} {if (num==0) {num=$1} else {sum=sum+(num-$1); num=$1}} END {print sum}'`
# среднее время обращений к серверу в секунду $sumtot
 sumtot=`echo $summ/$lines | bc`					# bc округляет до целого числа
 #sumtot=`echo $summ $lines | awk '{print $1/$2}'`			# awk умеет получать дробные числа
 echo "$acl : Среднее время обращения к серверу $sumtot сек. при минимальном $chks сек."
# генерация письма пользователю для BAN
 bntext=`echo -e "$dat с вашего почтового адреса $aclrep зафиксировано неприемлимое суточное число обращений к почтовому серверу НКМЗ."'\n' \
 "Необходимо установить частоту обращений к серверу не чаще 1 раза в 5 минут. "'\n' \
 "(Для адреса $aclrep производится обращение каждые $sumtot секунд)"'\n' \
 "В противном случае возможность использования почтового адреса $aclrep будет приостановленна Системой Защиты Почтового Сервера НКМЗ."'\n\n' \
 "---"'\n'"Администратор электронной почты НКМЗ, т.63-19, 61-65" | $reco`
 if [ $sumtot -lt $chks ]						# если $sumtot < $chks - создаем блокирующее правило в ipfw
  then
   if [ $lines -le $chkm ]						# проверка на частое нажатие кнопки принятия почты
    then
    echo "Ow, you're the fucking Clicker: " $acl, $addr
    printf "%-12sCLICK   %-18s pings:$lines<$chkm--time:$sumtot<$chks\t " $dat $acl >> ./logs/$logf.log
    printf "%-16s" $addr >> ./logs/$logf.log
    printf "\n" >> ./logs/$logf.log
    rm _02
    return 1
   fi
   echo "Catched you, bitch: " $acl, $addr
   #/sbin/ipfw -q add 2000 deny ip from $addr to 10.101.2.2 25,110,119,465,995 setup
#   echo -e $dat'\t'"BAN"'\t'$acl'\t'"time:$sumtot<$chks"'\t'$addr >> ./logs/$logf.log
   printf "%-12sBAN     %-18s time:$sumtot<$chks\t " $dat $acl >> ./logs/$logf.log
   printf "%-16s" $addr >> ./logs/$logf.log
   printf "\n" >> ./logs/$logf.log
   echo $bntext | mail -s "$ddsub" $acl					# отправка письма пользователю
  else
   echo "$acl is clean!"
#   echo -e $dat'\t'"CLEAN"'\t'$acl'\t'"time:$sumtot>$chks"'\t'$addr >> ./logs/$logf.log
   printf "%-12sCLEAN   %-18s time:$sumtot>$chks\t " $dat $acl >> ./logs/$logf.log
   printf "%-16s" $addr >> ./logs/$logf.log
   printf "\n" >> ./logs/$logf.log
 fi
 rm _02
}
#---------------#
# Старт скрипта #
#---------------#
arr=(`grep " Stats: " $mesf | awk '{print $7}' | sort -u`)		# создаем массив ACL-ов
#echo ${arr[*]}
while [ -n "${arr[i]}" ]						# выполняем проверку по ACL-ам, пока они не закончатся
do
 funk ${arr[i]}
 (( i+=1 ))
done
grep "DDOS\|BAN\|CLICK" ./logs/$logf.log > ./logs/$logf-ban.log		# отсеиваем DDOS и BAN
grep EXCEPT ./logs/$logf.log > ./logs/$logf-exc.log			# отсеиваем EXCEPT
# удаление старых логов
find ./logs -type f -name "*.log" \! -newermt '30 days ago' -exec rm -f {} \;
