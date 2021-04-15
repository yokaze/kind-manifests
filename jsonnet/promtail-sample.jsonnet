(import 'loki.jsonnet') +
(import 'prometheus-promtail.jsonnet') +
(import '../grafana/loki.jsonnet') + [
  import '../promtail/config-sample.jsonnet',
  import '../promtail/pod-sample.json',
  import '../promtail/service.json',
]
