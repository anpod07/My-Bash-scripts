#!/usr/local/bin/bash
# -------------------------------------------------------- #
# удаление несуществующих (удаленных) аклов из БД OpenLDAP #
# -------------------------------------------------------- #
homepath="/usr/home/ivan/online/ldap_clear_db"
workpath="/usr/local/etc/openldap"
cd $homepath
# получаем список всех аклов из БД
ldapsearch -x -s one -LLL -b 'dc=nkmz,dc=donetsk,dc=ua' "(cn=*)" | grep "^dn: " | awk -F "cn=|," '/cn=.*,/{print $2}' | sort > zzz1
# получаем список всех активных аклов из файла /usr/local/etc/openldap/allusers.ldif
grep "^dn: " $workpath/allusers.ldif | awk -F "cn=|," '/cn=.*,/{print $2}' | sort -u > zzz2
# получаем список тех, кто есть в БД, но нет в allusers.ldif. Формируем файл для удаления этих записей из БД
diff zzz1 zzz2 | grep "^< " | awk '{print "cn="$2",dc=nkmz,dc=donetsk,dc=ua"}' > u2del.ldif
cat u2del.ldif
# удаляем из БД несуществующие аклы, использую ранее созданный файл u2del.ldif
echo -n "Файл u2del.ldif - сформирован. Начать удаление записей из БД LDAP? (y/n)"; read i
if [ "$i" == "y" -o "$i" == "Y" ]
 then
  ldapdelete -w secret -c -x -D "cn=manager,dc=nkmz,dc=donetsk,dc=ua" -f u2del.ldif
 else echo "БД не изменена."
fi
