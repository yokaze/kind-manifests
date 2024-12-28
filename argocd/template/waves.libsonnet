local checkpoints = {
  argocd: 'checkpoints-argocd',
  ca: 'checkpoints-ca',
  cni: 'checkpoints-cni',
  init: 'checkpoints-init',
  istio: 'checkpoints-istio',
  metrics: 'checkpoints-metrics',
};
local dependency = {
  accurate: [
    checkpoints.argocd,
    checkpoints.ca,  // webhook
  ],
  'approver-policy': [
    'cert-manager',
  ],
  argocd: [checkpoints.istio],
  'cert-manager': [checkpoints.cni],
  'cluster-ca': ['approver-policy', 'cert-manager'],
  cadvisor: [checkpoints.argocd],
  cilium: [checkpoints.init],
  dashboard: [checkpoints.argocd],
  'datasource-pyroscope': ['grafana', 'pyroscope'],
  'datasource-vm': ['grafana', 'victoria-metrics'],
  deck: [checkpoints.argocd],
  gatekeeper: [checkpoints.cni],
  'gatekeeper-policy': ['gatekeeper-template'],
  'gatekeeper-template': ['gatekeeper'],
  grafana: [checkpoints.argocd],
  headlamp: [checkpoints.argocd],
  istio: ['istio-base'],
  'istio-base': [
    'crds',  // Gateway CRD
  ],
  'kube-state-metrics': [checkpoints.argocd],
  kubescape: [checkpoints.argocd],
  'node-exporter': [checkpoints.argocd],
  'profile-cilium': ['pyroscope'],
  'pyroscope': [checkpoints.argocd],
  'scrape-cadvisor': [checkpoints.metrics, 'cadvisor'],
  'scrape-ksm': [checkpoints.metrics, 'kube-state-metrics'],
  'scrape-node-exporter': [checkpoints.metrics, 'node-exporter'],
  'victoria-metrics': [
    checkpoints.argocd,
    checkpoints.ca,  // webhook
  ],
  [checkpoints.argocd]: ['argocd'],
  [checkpoints.ca]: ['cluster-ca'],
  [checkpoints.cni]: ['cilium'],
  [checkpoints.init]: ['crds', 'namespaces'],
  [checkpoints.istio]: ['istio'],
  [checkpoints.metrics]: ['datasource-vm', 'victoria-metrics'],
};
local resolve_once = function(nodes)
  std.set(std.flattenArrays(std.prune(std.map(function(x) std.get(dependency, x), nodes))));
local resolve = function(wave, steps, nodes)
  local app_nodes = std.setDiff(nodes, std.objectValues(checkpoints));
  local checkpoint_nodes = std.setInter(nodes, std.objectValues(checkpoints));
  if std.length(checkpoint_nodes) > 0 then
    resolve(wave, steps, std.set(app_nodes + resolve_once(checkpoint_nodes)))
  else if std.length(app_nodes) > 0 then
    resolve(wave + 1, std.set(steps + app_nodes), resolve_once(app_nodes))
  else {
    dependencies: steps,
    wave: wave,
  };
{
  get_all_dependencies(names)::
    resolve(0, [], names).dependencies,

  order(name)::
    if name == 'config' then 10000 else resolve(0, [], [name]).wave,
}
