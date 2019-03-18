#!/bin/bash


CONTAINER_REPLACEMENTS=(
  'quay.io/coreos/etcd-operator,cachengo/etcd-operator'
  'quay.io/coreos/etcd,quay.io/coreos/etcd'
  'lwolf/kubectl_deployer,iecedge/kubectl_deployer_arm64'
  'solsson/kafka-prometheus-jmx-exporter@sha256,iecedge/kafka-prometheus-jmx-exporter_arm64'
  'danielqsj/kafka-exporter,iecedge/kafka-exporter_arm64'
  'confluentinc/cp-kafka,akrainoenea/cp-kafka'
  'gcr.io/google_samples/k8szk,iecedge/k8szk_arm64'
  'sscaling/jmx-prometheus-exporter,iecedge/jmx-prometheus-exporter_arm64'
  'josdotso/zookeeper-exporter,akrainoenea/zookeeper_exporter'
  'docker.elastic.co/elasticsearch/elasticsearch-oss,akrainoenea/elasticsearch-oss'
  'busybox,busybox'
  'gcr.io/google-containers/fluentd-elasticsearch,akrainoenea/fluentd-elasticsearch'
  'docker.elastic.co/kibana/kibana-oss,akrainoenea/kibana-oss'
  'docker.elastic.co/logstash/logstash-oss,akrainoenea/logstash-oss'
  'bonniernews/logstash_exporter,akrainoenea/logstash_explorer'
  'opencord/kafka-topic-exporter,akrainoenea/kafka-topic-exporter'
  'grafana/grafana,grafana/grafana'
  'appropriate/curl,akrainoenea/curl'
  'kiwigrid/k8s-sidecar,akrainoenea/k8s-sidecar'
  'prom/alertmanager,akrainoenea/alertmanager'
  'jimmidyson/configmap-reload,carlosedp/configmap-reload'
  'busybox,busybox'
  'quay.io/coreos/kube-state-metrics,akrainoenea/kube-state-metrics'
  'prom/node-exporter,akrainoenea/node-exporter'
  'prom/prometheus,akrainoenea/prometheus'
  'prom/pushgateway,akrainoenea/pushgateway'
  'onosproject/onos,cachengo/onos'
  'docker.elastic.co/beats/filebeat-oss,akrainoenea/filebeat-oss'
  'xosproject/xos-core,cachengo/xos-core'
  'xosproject/chameleon,cachengo/chameleon'
  'xosproject/xos-tosca,cachengo/xos-tosca'
  'xosproject/xos-api-tester,cachengo/xos-api-tester'
  'postgres,postgres'
  'xosproject/xos-gui,cachengo/xos-gui'
  'xosproject/xos-ws,cachengo/xos-ws'
  'xosproject/tosca-loader,cachengo/tosca-loader'
  'xosproject/kubernetes-synchronizer,cachengo/kubernetes-synchronizer'
  'xosproject/tosca-loader,cachengo/tosca-loader'
  'xosproject/xos-api-tester,cachengo/xos-api-tester'
  'xosproject/fabric-synchronizer,cachengo/fabric-synchronizer'
  'xosproject/fabric-crossconnect-synchronizer,cachengo/fabric-crossconnect-synchronizer'
  'xosproject/onos-synchronizer,cachengo/onos-synchronizer'
  'xosproject/rcord-synchronizer,cachengo/rcord-synchronizer'
  'opencord/sadis-server,cachengo/sadis-server'
  'xosproject/volt-synchronizer,cachengo/volt-synchronizer'
  'voltha/voltha-voltha,cachengo/voltha-voltha'
  'voltha/voltha-cli,cachengo/voltha-cli'
  'voltha/voltha-ofagent,cachengo/voltha-ofagent'
  'voltha/voltha-netconf,cachengo/voltha-netconf'
  'voltha/voltha-envoy,cachengo/voltha-envoy'
  'voltha/voltha-alarm-generator,cachengo/voltha-alarm-generator'
  'tpdock/freeradius,cachengo/freeradius'
  'gcr.io/google_containers/defaultbackend,gcr.io/google_containers/defaultbackend-arm64'
  'quay.io/kubernetes-ingress-controller/nginx-ingress-controller,quay.io/kubernetes-ingress-controller/nginx-ingress-controller-arm64'
  'alpine,alpine'
  'quay.io/coreos/etcd,cachengo/etcd'
)

for REPLACEMENT in ${CONTAINER_REPLACEMENTS[@]}; do
  OLD="$(cut -d',' -f1 <<<$REPLACEMENT)"
  NEW="$(cut -d',' -f2 <<<$REPLACEMENT)"
  echo "Replacing $OLD with $NEW"
  # Use : as separator because it is an ilegal character in docker image names
  find . -name '*.yaml' -exec sed -i -e "s:$OLD:$NEW:g" {} \;
done
