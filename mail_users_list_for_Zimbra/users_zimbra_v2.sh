#!/usr/local/bin/bash
#=================================#
# Список пользователей для Zimbra #
#=================================#

# В качестве MTA: mail.nkmz.donetsk.ua. Zimbra может работать с несколькими разными MTA, например mail.nkmz.com
suf="@nkmz.donetsk.ua"
# pr_raboty=$2=1, email=$11, fam=$3, name=$4, midname=$5, dep=$8, prof=$9
# pr_raboty=$2="", email=$11, fam=$12, dep=$13
fl=/home/prx/scripts/sqlplus_all/all

# Получаем файл с нужными полями, без пароля
awk -F ";_;" '{if (length($2)<1 && length($11)>1) {print $11suf";"sq sq";"sq sq";"sq sq";"sq$12sq";"sw$12,"-",$13sw} \
			   else {if ($2~"1" && length($11)>1) {print $11suf";"sq$4sq";"sq$3sq";"sq$5sq";"sq$3,$4sq";"sw$3,$4,$5,"-",$8,"-",$9sw}} \
			  }' suf=$suf sq="'" sw='"' $fl > _1
echo "_1 : Ready"

# Генерим файл с паролями по количеству строк в предыдущем файле
arr=(`awk -F ";" '{print $1}' _1`)
i=0; :>_2
for i in "${arr[@]}"; do
 echo "$i;$(echo `dd if=/dev/random bs=10 count=1 2>/dev/null | openssl base64 | grep -o '[[:alnum:]]' | head -n 6 | tr -d '\n'`)" >> _2
done
echo "_2 : Ready"

# Объединяем файлы
awk -F ";" '{{if (FILENAME == "_1") {pop[$1] = $0; next}} \
             {if (FILENAME != "_1") {print pop[$1] ";" $2}}}' _1 _2 |\
             awk -F ";" 'OFS=";" {print "createAccount",$1,$7,"givenName",$2,"sn",$3,"initials",$4,"displayName",$5,"description",$6}' |\
             tr -s ";" " " > result
rm _1 _2
