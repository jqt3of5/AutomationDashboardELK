docker run --net=elastic --name logstash --volume=logstash.yml:/usr/share/logstash/config/logstash.yml docker.elastic.co/logstash/logstash:7.6.2
