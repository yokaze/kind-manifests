local kustomization = import 'kustomization.libsonnet';
kustomization([
  'argocd',
  'cadvisor',
  'deck',
  'grafana-operator',
  'grafana',
  'httpd',
  'istio',
  'kube-state-metrics',
  'node-exporter',
  'victoria-metrics',
  'vm-operator',
])
