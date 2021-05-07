{
  apiVersion: 'rbac.authorization.k8s.io/v1',
  kind: 'ClusterRole',
  metadata: {
    name: 'prometheus',
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
}
