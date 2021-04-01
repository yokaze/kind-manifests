std.mergePatch(import 'config-prometheus.jsonnet', {
  data: {
    'loki.yaml': importstr 'resources/datasource-loki.yaml',
  },
})
