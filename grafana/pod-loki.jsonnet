std.mergePatch(import 'pod.json', {
  spec: {
    volumes: [
      {
        name: 'datasources',
        configMap: {
          name: 'grafana-datasource',
          items: [
            {
              key: 'prometheus.yaml',
              path: 'prometheus.yaml',
            },
            {
              key: 'loki.yaml',
              path: 'loki.yaml',
            },
          ],
        },
      },
    ],
  },
})
