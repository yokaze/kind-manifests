{
  configs: {
    cm: {
      'kustomize.buildOptions': '--enable-helm',
      url: 'https://argocd-server.argocd',
    },
    params: {
      'redis.compression': 'none',
      'server.insecure': 'true',
    }
  },
}
