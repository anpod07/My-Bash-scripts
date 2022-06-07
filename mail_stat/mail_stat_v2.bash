#!/usr/local/bin/bash
# ============================================================================================= #
# Сбор почтовой статистики (Дата ; Отправитель ; Получатели ; Размер) из архива /usr/mail.log/*
# ============================================================================================= #
# Требуются:
#  - требуемые файлы архива /usr/mail.log/mail.log.*.gz
#  - поиск Получателя проводится по заголовоку 'To_bcc:', который включается на IronPort c190
# ============================================================================================= #
# функция для устанения мусора в финальных строках From: и To_bcc:
funk ()
{
 arr2=(); k=0
 arr2=(`echo "$1" | tr ";" " " | tr "<" " " | tr -d ">" | tr -d ","`)
 while [ -n "${arr2[k]}" ]; do
  if grep -q "@\|undisclosed-recipient" <<< ${arr2[k]}; then
   echo -n " ${arr2[k]}" >> zzz
  fi
  ((k++))
 done
 echo "" >> zzz
}

cd /root/scripts/mail_stat
fl="mail.log"
#n=0; ne=5												# нач. и кон. цифры имен архивных файлов
n=0; ne=0
export LC_CTYPE=C										# дефолтная кодировка, чтобы работал 'tr' не ругался на кириллицу (tr: Illegal byte sequence)
while [ $n -le $ne ]; do
 # Разорхивируем архив, удаляем первую и последнюю строки с инф. о ротации лога, если они есть
 zcat /usr/mail.log/mail.log.$n.gz | sed '/]: logfile turned over/d' > ./$fl
# zcat /usr/home/prx/mail.logs/mail.log.$n.gz > ./mail.log
 echo "mail.log.$n.gz unziped"
 # разбиваем архив на файлы, файл = письмо
 cd ./mess
 if [ -n "$(ls -A)" ]; then rm 0*; fi					# удаляем файлы 0*, если директория не пустая
 cat ../$fl | split -p "^From " -a5 - 0
 echo "Splitting of $fl - complite!"
 cd ..
 arr=(`ls ./mess`)										# массив файлов-писем суточного архива
 i=0; :>zzz
 while [ -n "${arr[i]}" ]; do
  echo `head -n1 ./mess/${arr[i]} | awk '{print $7"_"$4"_"$5"_"$6}'` >> zzz		# !!! вписал Дату
  ls -l ./mess/${arr[i]} | awk '{print " "$5}' >> zzz							# !!! вписал Размер письма

# === Достаем From: ===
  ar0=(`grep -nim1 "^From:" ./mess/${arr[i]} | tr " " ";" | sed -e "s/\'.*\'//" | sed -e 's/\".*\"//'`)
  if grep -q "@" <<< "${ar0[0]}"						# если строка содержит '@'
   then funk `echo ${ar0[0]} | tr " " ";"`				# !!! вписал From:
   else
    k1=`echo ${ar0[0]} | awk -F: '{print $1}'`			# номер текущей строки
    ext=$k1												# сохраняем номер первой строки поиска
    y=""
    while [ -z "$y" ]; do
     ((k1++))
     if [ $(($k1-$ext)) -eq 10 ]						# экстренный выход из цикла, если число повторений достигло 10
      then y=a; echo " undisclosed_sender" >> zzz
      else
       k2=`awk '(NR==x1)' x1="$k1" ./mess/${arr[i]}`	# проверяемая строка
       if grep -q "@" <<< "$k2"
        then y=a; echo "$k1 : $k2"
         funk `echo $k2 | tr " " ";"`					# !!! вписал From:
       fi
     fi
    done
  fi

# === Достаем To_bcc: (в нем есть To:, Cc: и Bcc:) ===
  ar0=(`grep -nm1 "^To_bcc:" ./mess/${arr[i]} | tr " " ";"`)
  if [ -z "${ar0[0]}" ]
   then echo " no_To_bcc" >> zzz
   else
    if grep -q "@" <<< "${ar0[0]}"						# если строка содержит '@'
     then
      if grep -qi ':To_bcc:.*,$' <<< "${ar0[0]}"		# если письмо отправлено на несколько адресов (в конце - запятая)
       then
        k1=`echo ${ar0[0]} | awk -F: '{print $1}'`		# номер текущей строки
        str=${ar0[0]}									# текущая строка
        y=""
        while [ -z "$y" ]; do
         ((k1++))										# берем номер следующей строки
         k2=`awk '(NR==x1)' x1="$k1" ./mess/${arr[i]}`	# следующая строка
         str+=$k2										# дописываем к текущей строке следующую
         if grep -qv ',$' <<< "$k2"						# если в конце - не запятая, выводим строку с несколькими отправителями
          then y=a; echo "$k1 ::: $str"
		   funk `echo $str | tr " " ";"`
         fi
        done
       else funk `echo ${ar0[0]} | tr " " ";"`			# !!! вписываем To_bcc:
      fi
     else
      k1=`echo ${ar0[0]} | awk -F: '{print $1}'`		# номер текущей строки
      ext=$k1											# сохраняем номер первой строки поиска
      y=""
      while [ -z "$y" ]; do
       ((k1++))
       if [ $(($k1-$ext)) -eq 5 ]						# экстренный выход из цикла, если число повторений достигло 5
        then y=a; echo "undisclosed_recipient" >> zzz
        else
         k2=`awk '(NR==x1)' x1="$k1" ./mess/${arr[i]}`	# проверяемая строка
         if grep -q "@" <<< "$k2"
          then y=a; echo "$k1 :: $k2"
           funk `echo $k2 | tr " " ";"`					# !!! вписал To_bcc:
         fi
       fi
      done
    fi
  fi
  ((i++))
 done

# === Формирую список: Дата ; Размер письма ; Отправитель ; Получатель ===
 d=`head -n1 zzz | awk -F "_" '{print $1"_"$2"_"$3}'`
 awk '{if (match($0,"^20")) {s1=$0; getline; s2=$0; getline; s3=$0; getline; s4=$0; print s1 ";" s3 ";" s4 ";" s2}}' zzz > $d.log
 ((n++))
done
rm mail.log zzz ./mess/0*
