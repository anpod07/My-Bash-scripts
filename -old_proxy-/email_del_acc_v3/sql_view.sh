#!/usr/local/bin/bash
sqlplus u44700@train/... <<EOF
 select g.email||'  '||g.tmail||'  '||k.pr_rab||'  '||Initcap(k.fam_r)||'  '||Initcap(k.name_r)||'  '||Initcap(k.mid_name_r)
 FROM U44700.GZI_EMAIL g
 LEFT JOIN Human_Resource.V_ODT_OIVS k
 ON g.LN=k.LN
 WHERE email in ('kalimulinam', 'hudoliymg');
 disconnect
 exit
EOF
