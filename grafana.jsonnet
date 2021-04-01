(import 'prometheus.jsonnet') + [
  import 'grafana/secret.json',
  import 'grafana/config-prometheus.jsonnet',
  import 'grafana/pod.json',
]
