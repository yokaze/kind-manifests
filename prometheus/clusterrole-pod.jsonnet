[
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRole',
    metadata: {
      name: 'prometheus-pods',
    },
    rules: [
      {
        apiGroups: [
          '',
        ],
        resources: [
          'pods',
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
      name: 'prometheus-pods',
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'prometheus-pods',
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
