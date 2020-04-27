set +o history
export LOGSTASH_KEYSTORE_PASS=mypassword
set -o history
/usr/share/logstash/bin/logstash-keystore create
/usr/share/logstash/bin/logstash-keystore add JIRA_USER
/usr/share/logstash/bin/logstash-keystore add JIRA_PWD

