#!/bin/bash
MAIL="alert@mail.jp" 

## check hpacucli command
test -x /usr/sbin/hpacucli || ( echo "/usr/sbin/hpacucli not exists" &&  exit 1 )

## check disk status
DISK_STATUS=`/usr/sbin/hpacucli ctrl all show config`

## count number of error line
DISK_STATUS_FAILED=`echo "$DISK_STATUS" | grep Failed | wc -l`

## send mail when it would get error
if [ 0 -ne $DISK_STATUS_FAILED ]
then
  echo "$DISK_STATUS" | mail -s "`hostname` physicaldrive status Failed." $MAIL
fi
