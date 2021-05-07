{
  apiVersion: 'rbac.authorization.k8s.io/v1',
  kind: 'ClusterRole',
  metadata: {
    name: 'kubectl',
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
}
