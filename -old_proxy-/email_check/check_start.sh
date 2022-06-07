#!/usr/local/bin/bash
cd /usr/home/ivan/online/email_check
cp /var/log/messages messages						# живой файл не берем, т.к. он постоянно дополняется
mesf=messages								# скорее всего это файл /var/log/messages
excf=except                                                             # файл с исключениями для ACL-ов
i=0									# счетчик
: > ./logs/check2.log							# очищаем файл от прошлых результатов

# IP тех, кто не прописан в hosts
grep ": Stats: " $mesf | awk '{print $12 "\t" $7}' | grep '^[0-9]' | sort -u > ./logs/check1.log

# кто забирает почту с разных IP (скрипт работает на BASH с массивами и функциями, т.к. SHELL не умеет работать с массивами)
funk ()									# функция для проверки ACL-ов из массива arr[]
{
 acl=$1
 addr=`grep " Stats: $acl " $mesf | awk '{print $13}' | sort -u`
# не проверять ACL-ы из файла исключений except
 exacl=`grep -e ^$acl$ $excf`
 if [ "$exacl" = "$acl" ]
  then
   echo "Exception ACL ($exacl). Abort checking."
   return 1
 fi
 addrcol=`echo "$addr" | wc -l`
 if [ $addrcol -gt 1 ]
  then
   echo $acl catched!
   echo $acl $addr >> ./logs/check2.log
  else
   echo $acl
 fi
}
arr=(`grep " Stats: " $mesf | awk '{print $7}' | sort -u`)		# добавляем массив ACL-ов
#echo ${arr[*]}
while [ -n "${arr[i]}" ]						# выполняем проверку по ACL-ам, пока они не закончатся
do
 funk ${arr[i]}
 (( i+=1 ))
done
