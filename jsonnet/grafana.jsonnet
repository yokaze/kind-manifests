(import 'prometheus.jsonnet') + [
  import '../grafana/secret.jsonnet',
  import '../grafana/config-prometheus.jsonnet',
  import '../grafana/pod.jsonnet',
]
