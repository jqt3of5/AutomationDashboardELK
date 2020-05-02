FROM docker.elastic.co/logstash/logstash:7.6.2

COPY logstash-input-jira_poller-1.0.0.gem /usr/share/logstash
COPY logstash-filter-time_in_status-1.0.0.gem /usr/share/logstash

RUN bin/logstash-plugin install /usr/share/logstash/logstash-filter-time_in_status-1.0.0.gem
RUN bin/logstash-plugin install /usr/share/logstash/logstash-input-jira_poller-1.0.0.gem
