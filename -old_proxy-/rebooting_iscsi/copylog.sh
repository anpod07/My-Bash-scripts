#!/bin/sh
# copy this script in /usr/mail.log
# Копируем логи, если устройство da3s1d - примонтированно
cd /usr/mail.log
if [ -n "`df | grep da3s1d`" ]
 then
  echo "da3s1d already mounted. Copying logs..."
  a=`stat -f "%Sm" -t "%Y%m%d" /usr/mail.log/mail.log.90.gz`
  b="cp /usr/mail.log/mail.log.90.gz /maillog/"$a".maillog.gz"
  `$b`
 else
  echo "da3s1d not found"
fi
