{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'loki',
    labels: {
      app: 'loki',
    },
  },
  spec: {
    containers: [
      {
        name: 'loki',
        image: 'grafana/loki:2.2.0',
      },
    ],
  },
}
