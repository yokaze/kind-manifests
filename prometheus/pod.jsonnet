{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'prometheus',
    labels: {
      app: 'prometheus',
    },
  },
  spec: {
    containers: [
      {
        name: 'prometheus',
        image: 'prom/prometheus:v2.25.0',
        volumeMounts: [
          {
            name: 'config',
            mountPath: '/etc/prometheus',
            readOnly: true,
          },
        ],
      },
    ],
    volumes: [
      {
        name: 'config',
        configMap: {
          name: 'prometheus',
        },
      },
    ],
  },
}
