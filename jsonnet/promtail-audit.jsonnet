(import 'loki.jsonnet') +
(import 'prometheus-promtail.jsonnet') +
(import '../grafana/loki.jsonnet') + [
  import '../promtail/config-audit.jsonnet',
  import '../promtail/pod-audit.jsonnet',
  import '../promtail/service.jsonnet',
]
