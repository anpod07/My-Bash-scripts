#!/usr/local/bin/bash
#-----------------------------------------------------------------------------------#
# пошаговое удаление акклов на основе ежесуточной проверки неиспользуемых email-ов  #
#-----------------------------------------------------------------------------------#
# цветной вывод
RED='\033[0;31m'	# Red Color
GRN='\033[0;32m'	# Green Color
LRED='\033[1;31m'	# Light Red Color
LGRN='\033[1;32m'	# Light Green Color
LBL='\033[1;36m'	# Light Blue Color
NC='\033[0m'		# No Color
wdir="/usr/home/ivan/online/email_del_acc_v3"
dtoday=`date +%s`	# текущая дата в секундах (Timestamp)
ytoday=`date +%Y`	# текущий год

# бэкапим /etc/hosts и /etc/mail/aliases
cp /etc/hosts $wdir/hosts_bd/hosts_`date +%Y_%m_%d`
cp /etc/mail/aliases $wdir/aliases_bd/aliases_`date +%Y_%m_%d`

# формируем массив акклов для удаления
#arr=(akulenko apuhtin arena)
#arr=(hawai vap registrator)
arr=(`awk -F\t '$3 == "DELETE_IT" {print $1}' _mess | awk 'gsub(" *","") {print $0}'`)
# формируем sql-запрос для отображения информации из БД 'gzi_email' по акклам из массива
:>_to_sql.sql
echo "select g.email||';_;'||g.tmail||';_;'||k.pr_rab||';_;'||Initcap(k.fam_r)||';_;'||Initcap(k.name_r)||';_;'||Initcap(k.mid_name_r)||';_;'||" > _sql_bd.sql
echo "k.n_podr||';_;'||k.prof" >> _sql_bd.sql
echo "FROM U44700.GZI_EMAIL g" >> _sql_bd.sql
echo "LEFT JOIN Human_Resource.V_ODT_OIVS k" >> _sql_bd.sql
echo "ON g.LN=k.LN" >> _sql_bd.sql
echo "WHERE email in (" >> _sql_bd.sql
i=0
while [ -n "${arr[i]}" ]; do
 if [ $i -eq 0 ]
  then echo "'${arr[i]}'" >> _sql_bd.sql
  else echo ",'${arr[i]}'" >> _sql_bd.sql
 fi
 ((i++))
done
echo ") ORDER BY email;" >> _sql_bd.sql
# берем инфромацию из БД
#sqlplus u44700@train/... < _sql_bd.sql | grep "^[a-z]" > _mess_bd
#sqlplus u44700@proj/... < _sql_bd.sql > _mess_bd
sqlplus -S u44700@proj/... <<EOF
 SET LINESIZE 110
 spool _mess_bd.lst
 @_sql_bd.sql
 spool off
 disconnect
 exit
EOF

# меню
i=0; inp=""
while [ -n "${arr[i]}" ]; do
 if [ "$inp" != "i" ]; then
  echo -en "${LGRN}USER${NC}:  ${LRED}${arr[i]}${NC} ___ "
  grep "^${arr[i]} " _mess | awk -F\t '{print $2}' | awk 'gsub("   *","") {print $0}'
  echo -en "${LGRN}CREATE DATE${NC}: "
  if grep -q "No such file or directory" <<< $(ls -ld /home/allother/${arr[i]} 2>&1)
   then echo -e "${RED}Home directory not found${NC}"
   else
    ls -ld /home/allother/${arr[i]} | awk '{print "\t"colg$6,$7,$8nocol,$9}' colg="${GRN}" nocol="${NC}"
    # дата создания акла < 6 месяцев (185 дней)?
    if grep -q ":" <<< "$(ls -ld /home/allother/${arr[i]} | awk '{print $8}')"	# проверяем наличие ":" в 8-ом поле (например, 2006 или 13:56)
     # если 8-е поле - время (13:56), то дописываем текущий год
     then dacl=`date -j -f "%d_%b_%Y_%T" "$(ls -ld /home/allother/${arr[i]} | awk '{print $6"_"$7"_"yr"_"$8}' yr="$ytoday")" "+%s"`
     # если 8-е поле - год (2006), оставляем без изменений
     else dacl=`date -j -f "%d_%b_%Y" "$(ls -ld /home/allother/${arr[i]} | awk '{print $6"_"$7"_"$8}')" "+%s"`
    fi
    if [ $(($dtoday-$dacl)) -lt 15984000 ]         # 1 day = 86400 sec, 185 days = 15984000 sec
     then echo -e "\t${LRED}${arr[i]}${NC}: дата создания ${GRN}меньше 6 месяцев${NC}"
     else echo -e "\t${LRED}${arr[i]}${NC}: дата создания ${RED}больше 6 месяцев${NC}"
    fi
  fi
  echo -en "${LGRN}HOSTS${NC}: "
  grep --color "[[:space:]]${arr[i]}.nkmz" /etc/hosts
  echo -en "${LGRN}MAILBOX${NC}: "
  ls -l /var/mail/${arr[i]} | awk '{print $9,$6,$7,$8,"size="$5/1000000" МБ"}' | grep --color "${arr[i]}"
  echo -en "\t"; head -n1 /var/mail/${arr[i]}
  echo -e "${LGRN}ALIAS${NC}: "
  grep --color "${arr[i]}" /etc/mail/aliases
  # если с акла идет переадресация, т.е. в 'aliases' есть строка типа: "<текущий акл>:  aaa, bbb, ...",- не удаляем из LDAP
  if [ -n "$(grep -m1 --color "^${arr[i]}:" aliases)" ]
   then echo -e "\tSaving ${GRN}LDAP${NC} record!"; ldapstat="noldap"
  fi
  echo -en "${LGRN}LDAP${NC}:  "
#  ldapsearch -x -LLL -b "cn=${arr[i]},dc=nkmz,dc=donetsk,dc=ua" sn description | grep --color -A3 "${arr[i]}"
  ldapsearch -x -LLL -b "cn=${arr[i]},dc=nkmz,dc=donetsk,dc=ua" dn | grep --color "${arr[i]}"
  echo -en "${LGRN}BD${NC}:     "
  # вставляем поля из БД, убрав лишние пробелы в конце последней строки (LINESIZE 110)
  case $(grep --color "^${arr[i]};_;" _mess_bd.lst | awk -F ";_;" '{print $3}') in
   "0" ) grep --color "^${arr[i]};_;" _mess_bd.lst |\
	 awk -F ";_;" 'gsub("      *","") {print collr$1nocol,$2,colr"уволен"nocol":",$4,$5,$6",",$7",",$8}' collr="${LRED}" colr="${RED}" nocol="${NC}";;
   "1" ) grep --color "^${arr[i]};_;" _mess_bd.lst |\
	 awk -F ";_;" 'gsub("      *","") {print collr$1nocol,$2,colg"работает"nocol":",$4,$5,$6",",$7",",$8}' collr="${LRED}" colg="${GRN}" nocol="${NC}";;
     * ) echo "No BD record found.";;
  esac
 fi
 echo -en "\nDelete(${LBL}1${NC}), Skip(${LBL}2${NC}), Mailbox Info(${LBL}i${NC}), Quit(${LBL}q${NC}): "
 read inp
 case $inp in
  "1" )
	# удаляем user-а по настоящему
	echo -e " Deleting user ${RED}${arr[i]}${NC}..."
	echo -e "y\ny\n" | rmuser ${arr[i]}
	# удаляем user-а тестово
#	echo -e " Deleting user ${RED}TEST123${NC} ..."
#	n="test123"
#	echo -e "y\ny\n" | rmuser $n
	# вычищаем из /etc/hosts
	echo -e " Deleting ${RED}${arr[i]}${NC} from /etc/hosts..."
	sed -e "/[[:space:]]${arr[i]}.nkmz/d" /etc/hosts > _h
	cat _h > /etc/hosts; rm _h
	# вычищаем из /etc/mail/aliases
	echo -e " Deleting ${RED}${arr[i]}${NC} from /etc/mail/aliases..."
	sed -E "/:[[:blank:]]+${arr[i]}$/d" /etc/mail/aliases |\
	sed -E "s/:[[:blank:]]+${arr[i]}, /:`echo -e "\t"`/; s/:[[:blank:]]+${arr[i]},/:`echo -e "\t"`/" |\
	sed "s/, ${arr[i]},/,/; s/,${arr[i]},/,/; s/, ${arr[i]}$//; s/,${arr[i]}$//" > _a
	cat _a > /etc/mail/aliases; rm _a
	# вычищаем из LDAP по настоящему
	if [ "$ldapstat" = "noldap" ]
	 then
	  echo -e " Skiping LDAP..."
	  ldapstat=""
	 else
	  echo -e " Deletind ${RED}${arr[i]}${NC} from LDAP..."
	  ldapdelete -x -v -D "cn=manager,dc=nkmz,dc=donetsk,dc=ua" -w secret "cn=${arr[i]},dc=nkmz,dc=donetsk,dc=ua"
	fi
	# вычищаем из LDAP тестово
#	echo -e " Deletind ${RED}apuhtinds${NC} from LDAP..."
#	n="apuhtinds"
#	ldapdelete -x -v -D "cn=manager,dc=nkmz,dc=donetsk,dc=ua" -w secret "cn=$n,dc=nkmz,dc=donetsk,dc=ua"
	# формируем файл для обновления БД gzi_email
	echo " Generating sql-file for update BD..."
	echo "UPDATE gzi_email SET tmail='DEL' WHERE email='${arr[i]}';" >> _to_sql.sql
	echo "===================================================================================="
	((i++))
	;;
  "2" )
	echo -e " Skiping...\n===================================================================================="
	((i++))
	;;
  "i" )
	echo -en "\t"; echo -e "x\n" | mail -Nu ${arr[i]} | tail -n1
	echo -e "\t-------------------------------------"
	;;
  "q" )
	echo -e "Exit\n===================================================================================="
	break
	;;
  * )
	echo -e " You entered some shit. Repeat\n===================================================================================="
	;;
 esac
done
# обновляем таблицу gzi_email
i=""
while [ "$i" != "q" ]; do
 echo -en "Update GZI_EMAIL table and Mail Aliases?\nUpdate(${LBL}y${NC}), Not update(${LBL}n${NC}), View sql-file(${LBL}v${NC}), Quit(${LBL}q${NC}): "
 read upd
 case $upd in
  "y" )
	# обновляем БД и БД Алиасов
        sqlplus u44700@proj/... < _to_sql.sql
        #sqlplus u44700@train/... < _to_sql.sql
        i="q"
        echo "Table updated successfully."
        newaliases
        echo "Mail Aliases updated successfully."
        ;;
  "n" )
        # не обновляем БД
        i="q"
        echo "Table not updated. Exit"
        ;;
  "v" )
        # смотрим _to_sql.sql
        if [ $(ls -l _to_sql.sql | awk '{print $5}') -eq 0 ]
         then echo -e "sql-file is empty\n===================================================================================="
         else
          echo -e "\t-------------------------------------"
          cat _to_sql.sql
          echo -e "\t-------------------------------------"
        fi
        ;;
  "q" )
	i="q"
        echo "Quit"
        ;;
  * )
        echo -e " You entered some shit. Repeat\n===================================================================================="
        ;;
 esac
done
rm _mess_bd.lst _to_sql.sql _sql_bd.sql
