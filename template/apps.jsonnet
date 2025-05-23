local template = import 'template-app.libsonnet';
local apps = [
  { name: 'accurate' },
  { name: 'accurate-gallery' },
  { name: 'approver-policy' },
  { name: 'argocd' },
  { name: 'base-policy' },
  { name: 'cadvisor' },
  { name: 'cert-manager' },
  { name: 'cilium' },
  { name: 'cluster-ca' },
  { name: 'collect-audit' },
  { name: 'collect-pods' },
  { name: 'config', sync: false, finalizer: false },
  { name: 'crd-gallery' },
  { name: 'crds' },
  { name: 'dashboard' },
  { name: 'datasource', sync: false },
  { name: 'deck' },
  { name: 'egress' },
  { name: 'gatekeeper' },
  { name: 'gatekeeper-policy' },
  { name: 'gatekeeper-template' },
  { name: 'grafana' },
  { name: 'grafana-dashboard' },
  { name: 'grafana-operator' },
  {
    name: 'istio',
    ignoreDifferences: [{
      group: 'admissionregistration.k8s.io',
      kind: 'ValidatingWebhookConfiguration',
      name: 'istio-validator-istio-system',
      jqPathExpressions: [
        '.webhooks[]?.failurePolicy',
      ],
    }],
  },
  {
    // https://github.com/istio/istio/issues/44285
    name: 'istio-base',
    ignoreDifferences: [{
      group: 'admissionregistration.k8s.io',
      kind: 'ValidatingWebhookConfiguration',
      name: 'istiod-default-validator',
      jqPathExpressions: [
        '.webhooks[]?.failurePolicy',
      ],
    }],
  },
  { name: 'istio-cni' },
  { name: 'headlamp' },
  { name: 'kiali' },
  { name: 'kube-state-metrics' },
  { name: 'kubescape' },
  { name: 'loki' },
  { name: 'moco' },
  { name: 'namespaces' },
  { name: 'node-exporter' },
  { name: 'pomerium' },
  { name: 'profile-cilium' },
  { name: 'proxy' },
  { name: 'pyroscope' },
  { name: 'scrape', sync: false },
  { name: 'spire-crds' },
  { name: 'spire' },
  { name: 'tempo' },
  { name: 'testhttpd' },
  { name: 'tetragon' },
  { name: 'traefik' },
  { name: 'traefik-route' },
  { name: 'trust-manager' },
  { name: 'victoria-metrics' },
];
[template(x) for x in apps]
