local checkpoints = import 'checkpoints.libsonnet';
local dependency = {
  accurate: [
    checkpoints.argocd,
    checkpoints.ca,  // webhook
  ],
  'approver-policy': [
    'cert-manager',
  ],
  argocd: [checkpoints.cni],
  'cert-manager': [checkpoints.cni],
  'cluster-ca': ['approver-policy', 'cert-manager'],
  cadvisor: [checkpoints.argocd],
  cilium: [checkpoints.init],
  'collect-audit': [checkpoints.logging],
  'collect-pods': [checkpoints.logging],
  dashboard: [checkpoints.argocd],
  deck: [checkpoints.argocd],
  gatekeeper: [checkpoints.cni],
  'gatekeeper-policy': ['gatekeeper-template'],
  'gatekeeper-template': ['gatekeeper'],
  grafana: ['grafana-operator'],
  'grafana-operator': [checkpoints.argocd],
  headlamp: [checkpoints.argocd],
  istio: ['istio-base', 'istio-cni'],
  'istio-base': [
    'crds',  // Gateway CRD
  ],
  'istio-cni': ['cilium'],
  kiali: [checkpoints.argocd, 'victoria-metrics'],
  'kube-state-metrics': [checkpoints.argocd],
  kubescape: [checkpoints.argocd],
  loki: [checkpoints.argocd],
  'node-exporter': [checkpoints.argocd],
  pomerium: [checkpoints.argocd],
  'profile-cilium': [checkpoints.profile],
  pyroscope: [checkpoints.argocd],
  tempo: [checkpoints.argocd],
  traefik: [checkpoints.argocd],
  'traefik-route': ['traefik'],
  'victoria-metrics': [
    checkpoints.argocd,
    checkpoints.ca,  // webhook
  ],
  [checkpoints.argocd]: ['argocd'],
  [checkpoints.ca]: ['cluster-ca'],
  [checkpoints.cni]: ['cilium', 'istio'],
  [checkpoints.init]: ['crds', 'namespaces'],
  [checkpoints.logging]: ['grafana', 'loki'],
  [checkpoints.metrics]: ['grafana', 'victoria-metrics'],
  [checkpoints.profile]: ['grafana', 'pyroscope'],
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

  order(spec)::
    if spec.sync then resolve(0, [], [spec.name]).wave else 10000,
}
