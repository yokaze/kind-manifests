local template = import 'template.libsonnet';
local apps = [
  { name: 'accurate' },
  { name: 'accurate-gallery' },
  { name: 'approver-policy' },
  { name: 'argocd' },
  { name: 'cadvisor' },
  { name: 'cert-manager' },
  { name: 'cilium' },
  { name: 'cluster-ca' },
  { name: 'collect-audit' },
  { name: 'collect-pods' },
  { name: 'config', sync: false, finalizer: false },
  { name: 'crds' },
  { name: 'dashboard' },
  { name: 'datasource', sync: false },
  { name: 'deck' },
  { name: 'egress' },
  { name: 'gatekeeper' },
  { name: 'gatekeeper-policy' },
  { name: 'gatekeeper-template' },
  { name: 'grafana' },
  { name: 'grafana-operator' },
  { name: 'istio-base' },
  { name: 'istio-cni' },
  { name: 'istio' },
  { name: 'headlamp' },
  { name: 'kiali' },
  { name: 'kube-state-metrics' },
  { name: 'kubescape' },
  { name: 'loki' },
  { name: 'namespaces' },
  { name: 'node-exporter' },
  { name: 'pomerium' },
  { name: 'profile-cilium' },
  { name: 'proxy' },
  { name: 'pyroscope' },
  { name: 'scrape', sync: false },
  { name: 'tempo' },
  { name: 'testhttpd' },
  { name: 'tetragon' },
  { name: 'traefik' },
  { name: 'traefik-route' },
  { name: 'victoria-metrics' },
];
[template(x) for x in apps]
