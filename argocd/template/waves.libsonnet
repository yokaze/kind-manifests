local checkpoints = {
  argocd: 'checkpoints-argocd',
  basic: 'checkpoints-basic',
  cni: 'checkpoints-cni',
  istio: 'checkpoints-istio',
};
local dependency = {
  accurate: [checkpoints.argocd, 'cert-manager'],
  argocd: [checkpoints.istio],
  'cert-manager': [checkpoints.cni],
  cilium: [checkpoints.basic],
  grafana: ['grafana-operator'],
  'grafana-operator': [checkpoints.argocd],
  istio: ['istio-base'],
  'istio-base': [checkpoints.cni],
  [checkpoints.argocd]: ['argocd'],
  [checkpoints.basic]: ['crds', 'namespaces'],
  [checkpoints.cni]: ['cilium'],
  [checkpoints.istio]: ['istio'],
};
local resolve_once = function(rest)
  std.flattenArrays(std.prune(std.map(function(x) std.get(dependency, x), rest)));
local resolve = function(wave, rest)
  if std.length(rest) == 0 then wave else resolve(wave + 1, resolve_once(rest));
function(name)
  if name == 'config' then 10000 else resolve(0, [name])
