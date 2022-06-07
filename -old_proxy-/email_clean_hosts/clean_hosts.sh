#!/usr/local/bin/bash
# чистим /etc/hosts от записей, ссылающихся на несуществующих пользователей /etc/master.passwd
grep -E "#service|#nouser" hosts > hosts_new			# генерим новый файл hosts
grep -Ev "#service|#nouser" hosts > _hosts_tmp			# оригинальный hosts без #service и #nouser (чтоб сравнивать было проще)
arrm=(`grep -v "^#" master.passwd | awk -F: '{print $1}'`)
#arrm=(osim pmo po aldokhindv)
i=0
while [ -n "${arrm[i]}" ]
do
 acl=`grep "[[:blank:]]${arrm[i]}.nkmz\>" _hosts_tmp | awk '{print $2}' | awk -F. '{print $1}'`
 echo "arrm[$i]: " ${arrm[i]}
 echo "acl: " $acl
 if [ "$acl" = "${arrm[i]}" ]
  then
   echo "ACL: ($acl)" >> _01
#   grep "\<${arrm[i]}\>" _hosts_tmp >> hosts_new
   grep "[[:blank:]]${arrm[i]}.nkmz\>" _hosts_tmp >> hosts_new
  else
   echo "ACL not detected: (${arrm[i]})"
#   grep "\<${arrm[i]}\>" _hosts_tmp >> hosts_not_detected
 fi
 (( i++ ))
done
sort -k 2 _hosts_tmp > _hosts_tmp_sort
grep -Ev "#service|#nouser" hosts_new | sort -k 2 > _new_sort
diff _hosts_tmp_sort _new_sort | grep "^<" | awk '{print $2 "\t\t" $3}' | sort -k 2 > hosts_diff
rm _*
