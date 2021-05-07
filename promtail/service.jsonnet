{
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    name: 'promtail',
  },
  spec: {
    selector: {
      app: 'promtail',
    },
    ports: [
      {
        port: 80,
      },
    ],
  },
}
