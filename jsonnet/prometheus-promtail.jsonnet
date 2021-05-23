[import '../prometheus/sa.jsonnet'] +
(import '../prometheus/clusterrole-pod.jsonnet') +
(import '../prometheus/clusterrole-service.jsonnet') + [
  import '../prometheus/config-promtail.jsonnet',
  import '../prometheus/pod-sa.jsonnet',
  import '../prometheus/service.jsonnet',
]
