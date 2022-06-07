SELECT email||';'||ip||';'||acl
FROM U44700.GZI_EMAIL
WHERE length(email)>0 and tmail='BAT';
