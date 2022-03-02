[{
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    namespace: 'argocd',
    name: 'sample-kustomize',
    finalizers: [
      'resources-finalizer.argocd.argoproj.io',
    ],
  },
  spec: {
    project: 'default',
    source: {
      repoURL: 'https://github.com/yokaze/kind-manifests.git',
      targetRevision: 'main',
      path: 'argocd/manifests/sample-kustomize',
    },
    destination: {
      server: 'https://kubernetes.default.svc',
      namespace: 'sample-kustomize',
    },
    syncPolicy: {
      automated: {
        prune: true,
        selfHeal: true,
      },
    },
  },
}]
