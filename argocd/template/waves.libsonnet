local checkpoints = {
  argocd: 'checkpoints-argocd',
  cni: 'checkpoints-cni',
  essential: 'checkpoints-essential',
  network: 'checkpoints-network',
};
local dependency = {
  accurate: [checkpoints.argocd],
  argocd: [checkpoints.network],
  cilium: [checkpoints.essential],
  'grafana-operator': [checkpoints.argocd],
  istio: ['istio-base', 'crds'],
  'istio-base': [checkpoints.cni],
  [checkpoints.argocd]: ['argocd'],
  [checkpoints.cni]: ['cilium'],
  [checkpoints.essential]: ['crds', 'namespaces'],
  [checkpoints.network]: ['cilium', 'istio'],
};
local resolve_once = function(rest)
  std.flattenArrays(std.prune(std.map(function(x) std.get(dependency, x), rest)));
local resolve = function(wave, rest)
  if std.length(rest) == 0 then wave else resolve(wave + 1, resolve_once(rest));
function(name)
  if name == 'config' then 10000 else resolve(0, [name])
