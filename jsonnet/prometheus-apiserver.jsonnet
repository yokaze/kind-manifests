[import '../prometheus/sa.jsonnet'] +
(import '../prometheus/clusterrole-apiserver.jsonnet') +
(import '../prometheus/clusterrole-pod.jsonnet') +
(import '../prometheus/clusterrole-service.jsonnet') + [
  import '../prometheus/config-apiserver.jsonnet',
  import '../prometheus/pod-sa.jsonnet',
  import '../prometheus/service.jsonnet',
]
