#!/usr/local/bin/bash
#----------------------------------------------#
# Поиск повторяющихся IP-адрессов в /etc/hosts #
#----------------------------------------------#
hosf=hosts
arrh=(`awk '{print $1, "1"}' $hosf | awk '{pop1[$1] += $2} END {for ( cc in pop1 ) {print cc, pop1[cc]}}' | awk '{if ($2 > 1) {print $1}}' | sort`)
while [ -n "${arrh[i]}" ]
do
 echo "Doubled IPs:"
 grep ^${arrh[i]}[[:blank:]] $hosf
 echo ""
 (( i+=1 ))
done
