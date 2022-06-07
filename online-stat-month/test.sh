#!/usr/local/bin/bash
# Замена части строки, содержащей 'что-то', на 'что-то другое' с сохранением оставшегося текста
awk '{if ($3 ~ "safeframe.googlesyndication.com") {print $1,$2,"safeframe.googlesyndication.com",$4} \
      else {if ($3 ~ "googlevideo.com") {print $1,$2,"googlevideo.com",$4} \
    	    else {if ($3 ~ "video.*ttvnw.net") {print $1,$2,"ttvnw.net",$4} \
    		  else {if ($3 ~ "metric.gstatic.com") {print $1,$2,"metric.gstatic.com",$4} \
    			else {print $0}}}}}' test.txt
