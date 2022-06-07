#!/usr/local/bin/bash
# Удаление всех запрещающих правил в IPFW для DDOS и BAN
arri=(`ipfw show | grep "25,110,119,465,995" | awk '{print $1}'`)
echo ${arri[*]}
if [ -z "${arri[*]}" ]
 then
  echo "Запрещающих правил не обнаружено. Отмена."
  exit 1
fi
echo "Удалить все правила? (y/n)"
read chyn
case "$chyn" in
 "Y" | "y" )
  echo "Правила удалены."
  ipfw delete ${arri[*]}
  ;;
 "N" | "n" )
  echo "Не удалять правила."
  exit 1
  ;;
 * )
  echo "Введена какая-то чушь. Отмена."
  exit 1
  ;;
esac
