(import 'loki.jsonnet') +
(import 'prometheus-promtail.jsonnet') +
(import '../grafana/loki.jsonnet') + [
  import '../promtail/config-sample.jsonnet',
  import '../promtail/pod-sample.jsonnet',
  import '../promtail/service.jsonnet',
]
