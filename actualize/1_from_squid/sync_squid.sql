SELECT acl||';'||ip
FROM U44700.GZI_EMAIL
WHERE length(acl)>0;
