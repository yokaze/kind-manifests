local checkpoints = import 'checkpoints.libsonnet';
local waves = import 'waves.libsonnet';
local features = {
  accurate: false,
  'accurate-gallery': true,
  'approver-policy': true,
  cadvisor: false,
  'collect-audit': false,
  'collect-pods': false,
  dashboard: false,
  deck: true,
  egress: true,
  'gatekeeper-policy': false,
  grafana: true,
  headlamp: true,
  kiali: true,
  'kube-state-metrics': false,
  kubescape: false,
  loki: false,
  'node-exporter': false,
  pomerium: false,
  'profile-cilium': false,
  pyroscope: false,
  tempo: false,
  testhttpd: true,
  tetragon: true,
  traefik: true,
  'traefik-route': true,
  'victoria-metrics': true,
};
local datasources = {
  loki: false,
  pyroscope: false,
  tempo: false,
  'victoria-metrics': false,
};
local scrapes = {
  argocd: false,
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
