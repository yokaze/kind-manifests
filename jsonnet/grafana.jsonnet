[import '../prometheus/sa.jsonnet'] +
(import '../prometheus/clusterrole-pod.jsonnet') + [
  import '../prometheus/config-grafana.jsonnet',
  import '../prometheus/pod-sa.jsonnet',
  import '../prometheus/service.jsonnet',
  import '../grafana/secret.jsonnet',
  import '../grafana/config-prometheus.jsonnet',
  import '../grafana/pod.jsonnet',
]
