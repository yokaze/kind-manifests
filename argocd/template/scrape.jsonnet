local kustomization = import 'kustomization.libsonnet';
kustomization([
  'argocd',
  'cadvisor',
  'istio',
  'ksm',
  'node-exporter',
])
