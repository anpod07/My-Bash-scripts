SELECT Initcap(k.fam_r)||';'||Initcap(k.name_r)||';'||Initcap(k.mid_name_r)||';'||k.n_podr||';'||k.prof||';'||g.acl
FROM U44700.GZI_EMAIL g
LEFT JOIN Human_Resource.V_ODT_OIVS k
ON g.LN=k.LN
WHERE length(acl)>0 and (g.tinet not like 'NS');
