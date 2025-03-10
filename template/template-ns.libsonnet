local pss = import 'pss.libsonnet';
local generate = function(spec)
  local labels =
    (if spec.istio then { 'istio-injection': 'enabled' } else {}) +
    (if spec.pss != pss.baseline then { 'pod-security.kubernetes.io/enforce': spec.pss } else {});
  {
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      name: spec.name,
    } + if std.length(labels) > 0 then { labels: labels } else {},
  };
function(spec)
  local required = [
    'name',
  ];
  local optional = {
    istio: false,
    pss: pss.baseline,
  };
  assert std.length(std.setDiff(required, std.objectFields(spec))) == 0 : 'required params are missing';
  generate(optional + spec)
