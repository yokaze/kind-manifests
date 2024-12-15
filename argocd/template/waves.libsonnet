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
  'istio-base': [
    checkpoints.cni,
    'crds',  // Gateway CRD
  ],
  'vm-cluster': ['vm-operator'],
  'vm-operator': [checkpoints.argocd],
  [checkpoints.argocd]: ['argocd'],
  [checkpoints.basic]: ['crds', 'namespaces'],
  [checkpoints.cni]: ['cilium'],
  [checkpoints.istio]: ['istio'],
};
local resolve_once = function(nodes)
  std.set(std.flattenArrays(std.prune(std.map(function(x) std.get(dependency, x), nodes))));
local resolve = function(wave, steps, nodes)
  if std.length(nodes) == 0 then {
    dependencies: steps,
    wave: wave,
  } else resolve(wave + 1, std.set(steps + nodes), resolve_once(nodes));
{
  get_all_dependencies(names)::
    std.setDiff(resolve(0, [], names).dependencies, std.objectValues(checkpoints)),

  order(name)::
    if name == 'config' then 10000 else resolve(0, [], [name]).wave,
}
