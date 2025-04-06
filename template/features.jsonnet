local checkpoints = import 'checkpoints.libsonnet';
local waves = import 'waves.libsonnet';
local features = {
  accurate: false,
  'accurate-gallery': false,
  'approver-policy': true,
  cadvisor: false,
  'collect-audit': false,
  'collect-pods': false,
  'crd-gallery': true,
  dashboard: false,
  deck: true,
  egress: true,
  'gatekeeper-policy': false,
  grafana: true,
  'grafana-dashboard': true,
  headlamp: true,
  kiali: true,
  'kube-state-metrics': true,
  kubescape: false,
  loki: false,
  'node-exporter': true,
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
local scrapes = {
  argocd: false,
  cadvisor: false,
  deck: true,
  'grafana-operator': false,
  grafana: true,
  httpd: true,
  'istio-system': true,
  'kube-state-metrics': true,
  'node-exporter': true,
  'victoria-metrics': true,
  'vm-operator': true,
};
local targets = waves.get_all_dependencies(
  [x for x in std.objectFields(features) if features[x]] +
  ['scrape/' + x for x in std.objectFields(scrapes) if scrapes[x]]
);
{
  apps: std.filter(
    function(x)
      !std.startsWith(x, 'datasource/') &&
      !std.startsWith(x, 'scrape/'),
    targets
  ),
  datasources: [std.strReplace(x, 'datasource/', '') for x in targets if std.startsWith(x, 'datasource/')],
  scrapes: [std.strReplace(x, 'scrape/', '') for x in targets if std.startsWith(x, 'scrape/')],
}
