local checkpoints = import 'checkpoints.libsonnet';
local dependency = {
  accurate: [
    checkpoints.argocd,
    checkpoints.ca,  // webhook
  ],
  'accurate-gallery': ['accurate'],
  'approver-policy': ['cilium'],
  argocd: [
    checkpoints.policy,
    'proxy',
  ],
  'base-policy': ['cert-manager'],
  'cert-manager': ['cilium'],
  'cluster-ca': ['approver-policy', 'cert-manager', 'trust-manager'],
  cadvisor: [checkpoints.argocd],
  cilium: [checkpoints.init],
  'collect-audit': [checkpoints.logging],
  'collect-pods': [checkpoints.logging],
  'crd-gallery': [checkpoints.argocd],
  dashboard: [checkpoints.argocd],
  datasource: ['grafana'],
  deck: ['proxy'],
  egress: [checkpoints.argocd],
  gatekeeper: ['proxy'],
  'gatekeeper-policy': ['gatekeeper-template'],
  'gatekeeper-template': ['gatekeeper'],
  grafana: ['grafana-operator'],
  'grafana-dashboard': ['grafana'],
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
  moco: [checkpoints.ca],
  'node-exporter': [checkpoints.argocd],
  pomerium: [checkpoints.argocd],
  'profile-cilium': [checkpoints.profile],
  proxy: ['trust-manager'],
  pyroscope: [checkpoints.argocd],
  'scrape/argocd': [checkpoints.metrics, 'argocd'],
  'scrape/cadvisor': [checkpoints.metrics, 'cadvisor'],
  'scrape/deck': [checkpoints.metrics, 'deck'],
  'scrape/grafana-operator': [checkpoints.metrics, 'grafana-operator'],
  'scrape/grafana': [checkpoints.metrics, 'grafana'],
  'scrape/httpd': [checkpoints.metrics, 'testhttpd'],
  'scrape/istio-system': [checkpoints.metrics, 'istio'],
  'scrape/kube-state-metrics': [checkpoints.metrics, 'kube-state-metrics'],
  'scrape/node-exporter': [checkpoints.metrics, 'node-exporter'],
  'scrape/victoria-metrics': [checkpoints.metrics, 'victoria-metrics'],
  'scrape/vm-operator': [checkpoints.metrics, 'victoria-metrics'],
  spire: ['cilium', 'spire-crds'],
  'spire-crds': [checkpoints.init],
  tempo: [checkpoints.argocd],
  testhttpd: [checkpoints.argocd],
  tetragon: ['proxy'],
  traefik: [checkpoints.argocd],
  'traefik-route': ['traefik'],
  'victoria-metrics': [
    checkpoints.argocd,
    checkpoints.ca,  // webhook
  ],
  'trust-manager': ['cert-manager'],
  [checkpoints.argocd]: ['argocd'],
  [checkpoints.ca]: ['cluster-ca'],
  [checkpoints.cni]: ['cilium', 'istio'],
  [checkpoints.init]: ['crds', 'namespaces'],
  [checkpoints.logging]: ['datasource', 'loki'],
  [checkpoints.metrics]: [
    'datasource',
    'datasource/victoria-metrics',
    'scrape',
    'victoria-metrics',
  ],
  [checkpoints.policy]: ['gatekeeper-policy', 'tetragon'],
  [checkpoints.profile]: ['datasource', 'pyroscope'],
  [checkpoints.tracing]: ['datasource', 'tempo'],
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
