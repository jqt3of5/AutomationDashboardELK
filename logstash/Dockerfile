FROM docker.elastic.co/logstash/logstash:7.6.2

COPY logstash-input-jira_poller-5.0.1.gem /usr/share/logstash

RUN bin/logstash-plugin install /usr/share/logstash/logstash-input-jira_poller-5.0.1.gem