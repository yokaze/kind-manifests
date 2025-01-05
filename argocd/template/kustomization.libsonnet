function(names) {
  apiVersion: 'kustomize.config.k8s.io/v1beta1',
  kind: 'Kustomization',
  resources: [('%s.yaml' % x) for x in names],
}
