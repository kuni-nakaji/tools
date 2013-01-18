# ------------------------------------------------
# a checking tool for access number per unit time
# ------------------------------------------------
EMAIL=lm-alert@realworld.jp
SUBJECT='[warn]IP_check'
LOG=/var/log/httpd/www_access_log
TMP=/tmp/tmp_lm_alert.log

if [ -f ${TMP} ]; then
  rm ${TMP}
fi

export LANG=C
date +"%Y/%m/%d:%H:%M:%S" > ${TMP}
grep "/login/" ${LOG}.`date +"%Y%m%d"`|grep `date +"%d/%h/%Y:%H"`|awk '{print $1}'|sort|uniq -c|awk '{if($1>10){print $0}}' >> ${TMP}

if [ `cat ${TMP}|wc -c` -gt 0 ]; then
 cat ${TMP}|mail -s ${SUBJECT} ${EMAIL};
 exit 0;
else
 exit 0;
fi

if [ -f ${TMP} ]; then
  rm ${TMP}
fi