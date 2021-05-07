{
  apiVersion: 'rbac.authorization.k8s.io/v1',
  kind: 'ClusterRoleBinding',
  metadata: {
    name: 'kubectl',
  },
  roleRef: {
    apiGroup: 'rbac.authorization.k8s.io',
    kind: 'ClusterRole',
    name: 'kubectl',
  },
  subjects: [
    {
      kind: 'ServiceAccount',
      namespace: 'default',
      name: 'kubectl',
    },
  ],
}