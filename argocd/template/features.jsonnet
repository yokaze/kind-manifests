local waves = import 'waves.libsonnet';
local features = {
  accurate: false,
  'approver-policy': true,
  cadvisor: false,
  dashboard: false,
  'datasource-pyroscope': true,
  'datasource-vm': false,
  deck: true,
  gatekeeper: true,
  grafana: true,
  headlamp: true,
  'kube-state-metrics': false,
  kubescape: true,
  'node-exporter': false,
  pyroscope: true,
  'scrape-cadvisor': false,
  'scrape-ksm': false,
  'scrape-node-exporter': false,
  'victoria-metrics': false,
};
waves.get_all_dependencies(
  [x for x in std.objectFields(features) if features[x]]
)
