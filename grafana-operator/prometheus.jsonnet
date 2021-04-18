[
  {
    apiVersion: 'integreatly.org/v1alpha1',
    kind: 'GrafanaDataSource',
    metadata: {
      name: 'prometheus',
    },
    spec: {
      name: 'prometheus',
      datasources: [{
        name: 'Prometheus',
        type: 'prometheus',
        url: 'http://prometheus:9090',
        isDefault: true,
      }],
    },
  },
]
