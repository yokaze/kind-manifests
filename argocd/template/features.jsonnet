local checkpoints = import 'checkpoints.libsonnet';
local waves = import 'waves.libsonnet';
local features = {
  accurate: false,
  'approver-policy': true,
  cadvisor: false,
  'collect-audit': true,
  'collect-pods': false,
  dashboard: false,
  'datasource-loki': true,
  'datasource-pyroscope': false,
  'datasource-tempo': false,
  'datasource-vm': false,
  deck: true,
  'gatekeeper-policy': false,
  grafana: true,
  headlamp: false,
  kiali: false,
  'kube-state-metrics': false,
  kubescape: false,
  loki: true,
  'node-exporter': false,
  pomerium: false,
  'profile-cilium': false,
  pyroscope: false,
  scrape: true,
  tempo: false,
  'victoria-metrics': false,
};
local scrapes = {
  argocd: false,
  cadvisor: false,
  istio: false,
  'kube-state-metrics': true,
  'node-exporter': false,
};
local scrape_targets = [x for x in std.objectFields(scrapes) if scrapes[x]];
{
  apps: waves.get_all_dependencies(
    [x for x in std.objectFields(features) if features[x]] +
    if std.any(std.objectValues(scrapes)) then [checkpoints.metrics] + scrape_targets else []
  ),
  scrapes: scrape_targets,
}
