local waves = import 'template/waves.libsonnet';
local features = {
  accurate: true,
  'approver-policy': true,
  deck: true,
  grafana: false,
  'grafana-vm': false,
  'vm-agent': false,
  'vm-cluster': false,
  'vm-operator': false,
};
waves.get_all_dependencies(
  [x for x in std.objectFields(features) if features[x]]
)
