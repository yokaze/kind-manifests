local checkpoints = import 'checkpoints.libsonnet';
local waves = import 'waves.libsonnet';
local features = {
  accurate: false,
  'approver-policy': true,
  cadvisor: false,
  'collect-audit': true,
  'collect-pods': true,
  dashboard: false,
  deck: true,
  'gatekeeper-policy': false,
  grafana: true,
  headlamp: false,
  kiali: false,
  'kube-state-metrics': false,
  kubescape: false,
  loki: false,
  'node-exporter': false,
  pomerium: false,
  'profile-cilium': false,
  pyroscope: false,
  tempo: false,
  'victoria-metrics': false,
};
local datasources = {
  loki: true,
  pyroscope: false,
  tempo: false,
  'victoria-metrics': false,
};
local scrapes = {
  argocd: true,
  cadvisor: false,
  istio: false,
  'kube-state-metrics': false,
  'node-exporter': false,
};
local datasource_targets = [x for x in std.objectFields(datasources) if datasources[x]];
local scrape_targets = [x for x in std.objectFields(scrapes) if scrapes[x]];
{
  apps: waves.get_all_dependencies(
    [x for x in std.objectFields(features) if features[x]] +
    (if std.any(std.objectValues(datasources)) then ['grafana'] + datasource_targets else []) +
    (if std.any(std.objectValues(scrapes)) then [checkpoints.metrics] + scrape_targets else []) +
    ['datasource', 'scrape']
  ),
  datasources: datasource_targets,
  scrapes: scrape_targets,
}
