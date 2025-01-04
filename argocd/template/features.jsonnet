local waves = import 'waves.libsonnet';
local features = {
  accurate: false,
  'approver-policy': true,
  cadvisor: false,
  dashboard: false,
  'datasource-loki': true,
  'datasource-pyroscope': false,
  'datasource-tempo': false,
  'datasource-vm': false,
  deck: true,
  'gatekeeper-policy': false,
  grafana: true,
  headlamp: false,
  kiali: false,
  'kube-state-metrics': false,
  kubescape: false,
  loki: true,
  'node-exporter': false,
  pomerium: false,
  'profile-cilium': false,
  pyroscope: false,
  'scrape-argocd': false,
  'scrape-cadvisor': false,
  'scrape-istio': false,
  'scrape-ksm': false,
  'scrape-node-exporter': false,
  tempo: false,
  'victoria-metrics': false,
};
waves.get_all_dependencies(
  [x for x in std.objectFields(features) if features[x]]
)
