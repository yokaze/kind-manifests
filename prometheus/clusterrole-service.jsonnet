[
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRole',
    metadata: {
      name: 'prometheus-services',
    },
    rules: [
      {
        apiGroups: [
          '',
        ],
        resources: [
          'endpoints',
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
      name: 'prometheus-services',
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'prometheus-services',
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
