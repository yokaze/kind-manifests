local template = import 'template.libsonnet';
local apps = [
  { name: 'accurate' },
  { name: 'approver-policy' },
  { name: 'argocd' },
  { name: 'cadvisor' },
  { name: 'cert-manager' },
  { name: 'cilium' },
  { name: 'cluster-ca' },
  { name: 'config', finalizer: false },
  { name: 'crds' },
  { name: 'dashboard' },
  { name: 'datasource-pyroscope' },
  { name: 'datasource-vm' },
  { name: 'deck' },
  { name: 'gatekeeper' },
  { name: 'grafana' },
  { name: 'istio-base' },
  { name: 'istio' },
  { name: 'headlamp' },
  { name: 'kube-state-metrics' },
  { name: 'kubescape' },
  { name: 'namespaces' },
  { name: 'node-exporter' },
  { name: 'pyroscope' },
  { name: 'scrape-cadvisor' },
  { name: 'scrape-ksm' },
  { name: 'scrape-node-exporter' },
  { name: 'victoria-metrics' },
];
[template(x) for x in apps]
