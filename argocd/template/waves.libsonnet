local checkpoints = {
  argocd: 'checkpoints-argocd',
  ca: 'checkpoints-ca',
  cni: 'checkpoints-cni',
  init: 'checkpoints-init',
  istio: 'checkpoints-istio',
};
local dependency = {
  accurate: [
    checkpoints.argocd,
    checkpoints.ca,
  ],
  argocd: [checkpoints.istio],
  'cert-manager': [checkpoints.cni],
  'cluster-ca': ['cert-manager'],
  cilium: [checkpoints.init],
  grafana: ['grafana-operator'],
  'grafana-operator': [checkpoints.argocd],
  istio: ['istio-base'],
  'istio-base': [
    'crds',  // Gateway CRD
  ],
  'vm-cluster': ['vm-operator'],
  'vm-operator': [
    checkpoints.argocd,
    checkpoints.ca,
  ],
  [checkpoints.argocd]: ['argocd'],
  [checkpoints.ca]: ['cluster-ca'],
  [checkpoints.cni]: ['cilium'],
  [checkpoints.init]: ['crds', 'namespaces'],
  [checkpoints.istio]: ['istio'],
};
local resolve_once = function(nodes)
  std.set(std.flattenArrays(std.prune(std.map(function(x) std.get(dependency, x), nodes))));
local resolve = function(wave, steps, nodes)
  local app_nodes = std.setDiff(nodes, std.objectValues(checkpoints));
  local checkpoint_nodes = std.setInter(nodes, std.objectValues(checkpoints));
  if std.length(checkpoint_nodes) > 0 then
    resolve(wave, steps, std.set(app_nodes + resolve_once(checkpoint_nodes)))
  else if std.length(app_nodes) > 0 then
    resolve(wave + 1, steps, resolve_once(app_nodes))
  else {
    dependencies: steps,
    wave: wave,
  };
{
  get_all_dependencies(names)::
    std.setDiff(resolve(0, [], names).dependencies, std.objectValues(checkpoints)),

  order(name)::
    if name == 'config' then 10000 else resolve(0, [], [name]).wave,
}
