local waves = import 'template/waves.libsonnet';
local features = {
  accurate: false,
  'approver-policy': true,
  deck: true,
  grafana: true,
  'grafana-vm': true,
  'kube-state-metrics': true,
  'node-exporter': true,
  'scrape-ksm': true,
  'scrape-node-exporter': true,
  'vm-agent': true,
  'vm-cluster': true,
  'vm-operator': true,
};
waves.get_all_dependencies(
  [x for x in std.objectFields(features) if features[x]]
)
