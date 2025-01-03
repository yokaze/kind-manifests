local waves = import 'waves.libsonnet';
local features = {
  accurate: false,
  'approver-policy': true,
  cadvisor: false,
  dashboard: false,
  'datasource-pyroscope': false,
  'datasource-vm': false,
  deck: true,
  'gatekeeper-policy': false,
  grafana: true,
  headlamp: false,
  kiali: true,
  'kube-state-metrics': false,
  kubescape: false,
  loki: false,
  'node-exporter': false,
  pomerium: false,
  'profile-cilium': false,
  pyroscope: false,
  'scrape-cadvisor': false,
  'scrape-ksm': false,
  'scrape-node-exporter': false,
  tempo: false,
  'victoria-metrics': false,
};
waves.get_all_dependencies(
  [x for x in std.objectFields(features) if features[x]]
)
