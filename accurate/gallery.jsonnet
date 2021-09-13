[
  {
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      name: 'sample-template',
      labels: {
        'accurate.cybozu.com/type': 'template',
      },
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      name: 'sample-root',
      labels: {
        'accurate.cybozu.com/template': 'sample-template',
        'accurate.cybozu.com/type': 'root',
      },
    },
  },
  {
    apiVersion: 'accurate.cybozu.com/v1',
    kind: 'SubNamespace',
    metadata: {
      namespace: 'sample-root',
      name: 'sample-sub',
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Secret',
    metadata: {
      namespace: 'sample-template',
      name: 'sample-template',
      annotations: {
        'accurate.cybozu.com/propagate': 'update',
      },
    },
    data: {
      key: 'dGVtcGxhdGU=',
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Secret',
    metadata: {
      namespace: 'sample-root',
      name: 'sample-root',
      annotations: {
        'accurate.cybozu.com/propagate': 'update',
      },
    },
    data: {
      key: 'cm9vdA==',
    },
  },
]
