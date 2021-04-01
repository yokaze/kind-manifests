{
  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    name: 'prometheus',
  },
  data: {
    'prometheus.yml': importstr 'resources/scrape-promtail.yml',
  },
}
