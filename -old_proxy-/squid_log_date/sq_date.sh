#!/usr/local/bin/bash
#
fl="/usr/local/squid/var/logs/access-old.log.0.0.gz"
cd /usr/home/ivan/online/squid_log_date
zcat $fl > access.log
echo "zcat DONE!"
awk -F "." '{print $0, system("date -r " $1 " +%Y-%b-%d-%T")}' access.log | awk '{print $11,$2,$3,$4,$5,$6,$7,$8,$9,$10}' | grep -v '^ ' > result
