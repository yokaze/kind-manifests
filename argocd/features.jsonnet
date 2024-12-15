local waves = import 'template/waves.libsonnet';
local features = {
  accurate: false,
  grafana: false,
  'vm-cluster': true,
  'vm-operator': true,
};
waves.get_all_dependencies(
  [x for x in std.objectFields(features) if features[x]]
)
