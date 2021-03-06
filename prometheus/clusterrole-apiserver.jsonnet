[
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRole',
    metadata: {
      name: 'prometheus-apiserver',
    },
    rules: [
      {
        nonResourceURLs: [
          '/metrics',
        ],
        verbs: [
          'get',
        ],
      },
    ],
  },
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRoleBinding',
    metadata: {
      name: 'prometheus-apiserver',
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'prometheus-apiserver',
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        namespace: 'default',
        name: 'prometheus',
      },
    ],
  },
]
