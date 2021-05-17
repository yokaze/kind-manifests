[
  {
    apiVersion: 'v1',
    kind: 'Secret',
    metadata: {
      name: 'grafana',
    },
    type: 'Opaque',
    data: {
      GF_SECURITY_ADMIN_USER: 'YWRtaW4=',
      GF_SECURITY_ADMIN_PASSWORD: 'cGFzc3dvcmQ=',
    },
  },
  {
    apiVersion: 'integreatly.org/v1alpha1',
    kind: 'Grafana',
    metadata: {
      name: 'grafana',
    },
    spec: {
      deployment: {
        envFrom: [{
          secretRef: {
            name: 'grafana',
          },
        }],
        skipCreateAdminAccount: true,
      },
      service: {
        name: 'grafana',
      },
    },
  },
]
