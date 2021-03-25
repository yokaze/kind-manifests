(import "loki.jsonnet") + 
(import "prometheus-loki.jsonnet") + [
    import "grafana/secret.json",
    import "grafana/config-loki.jsonnet",
    import "grafana/pod.json"
]
