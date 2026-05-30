local checkpoints = import 'checkpoints.libsonnet';
local waves = import 'waves.libsonnet';
local features = {
  accurate: false,
  'accurate-gallery': false,
  'approver-policy': true,
  cadvisor: false,
  'collect-audit': true,
  'collect-pods': true,
  'crd-gallery': false,
  'datasource/loki': true,
  'datasource/victoria-metrics': true,
  deck: true,
  'dependency-track': true,
  egress: true,
  'gatekeeper-policy': false,
  grafana: true,
  'grafana-dashboard': true,
  headlamp: true,
  kiali: false,
  'kube-state-metrics': false,
  kubescape: false,
  loki: false,
  'node-exporter': false,
  pomerium: false,
  'profile-cilium': false,
  pyroscope: false,
  tempo: true,
  testhttpd: true,
  tetragon: true,
  traefik: true,
  'traefik-route': true,
  'victoria-metrics': false,
};
local scrapes = {
  argocd: false,
  cadvisor: false,
  deck: false,
  'grafana-operator': false,
  grafana: false,
  httpd: false,
  'istio-system': false,
  'kube-state-metrics': false,
  'node-exporter': false,
  'victoria-metrics': false,
  'vm-operator': false,
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
