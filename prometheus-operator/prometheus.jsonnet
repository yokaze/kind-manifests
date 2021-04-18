[
  {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: {
      name: 'prometheus',
    },
  },
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRole',
    metadata: {
      name: 'prometheus',
    },
    rules: [
      {
        apiGroups: [
          '',
        ],
        resources: [
          'endpoints',
          'pods',
          'services',
        ],
        verbs: [
          'get',
          'watch',
          'list',
        ],
      },
    ],
  },
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRoleBinding',
    metadata: {
      name: 'prometheus',
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'prometheus',
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        namespace: 'default',
        name: 'prometheus',
      },
    ],
  },
  {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'Prometheus',
    metadata: {
      name: 'prometheus',
    },
    spec: {
      podMetadata: {
        labels: {
          app: 'prometheus',
        },
      },
      serviceAccountName: 'prometheus',
      serviceMonitorSelector: {},
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: 'prometheus',
    },
    spec: {
      ports: [{
        port: 9090,
      }],
      selector: {
        app: 'prometheus',
      },
    },
  },
]
