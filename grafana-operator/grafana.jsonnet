[
  {
    apiVersion: 'integreatly.org/v1alpha1',
    kind: 'Grafana',
    metadata: {
      name: 'grafana',
    },
    spec: {
      config: {
        security: {
          admin_user: 'admin',
          admin_password: 'password',
        },
      },
      service: {
        name: 'grafana',
      },
    },
  },
]
