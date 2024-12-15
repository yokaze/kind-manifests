local waves = import 'template/waves.libsonnet';
local features = {
  accurate: false,
  deck: true,
  grafana: true,
  'grafana-vm': true,
  'vm-cluster': true,
  'vm-operator': true,
};
waves.get_all_dependencies(
  [x for x in std.objectFields(features) if features[x]]
)
