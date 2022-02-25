[{
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    namespace: 'argocd',
    name: 'sample',
  },
  spec: {
    project: 'default',
    source: {
      repoURL: 'https://github.com/yokaze/kind-manifests.git',
      targetRevision: 'main',
      path: 'argocd/manifests/sample',
    },
    destination: {
      server: 'https://kubernetes.default.svc',
      namespace: 'sample',
    },
  },
}]
