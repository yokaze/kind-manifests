local kustomization = import 'kustomization.libsonnet';
kustomization([
  'argocd',
  'cadvisor',
  'istio',
  'kube-state-metrics',
  'node-exporter',
])
