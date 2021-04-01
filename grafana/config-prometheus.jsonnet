{
  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    name: 'grafana-datasource',
  },
  data: {
    'prometheus.yaml': importstr 'resources/datasource-prometheus.yaml',
  },
}
