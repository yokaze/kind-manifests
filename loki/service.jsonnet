{
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    name: 'loki',
  },
  spec: {
    selector: {
      app: 'loki',
    },
    ports: [
      {
        port: 3100,
      },
    ],
  },
}
