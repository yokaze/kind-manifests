local waves = import 'waves.libsonnet';
local generate = function(spec) {
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    namespace: 'argocd',
    name: spec.name,
    annotations: {
      'argocd.argoproj.io/sync-wave': std.toString(waves(spec.name)),
    },
  } + if spec.finalizer then {
    finalizers: [
      'resources-finalizer.argocd.argoproj.io',
    ],
  } else {},
  spec: {
    destination: {
      namespace: 'argocd',
      server: 'https://kubernetes.default.svc',
    },
    project: 'default',
    source: {
      repoURL: 'https://github.com/yokaze/kind-manifests.git',
      path: 'argocd/generated/%s' % spec.name,
    },
  },
  syncPolicy: {
    automated: {
      prune: true,
      selfHeal: true,
    },
  },
};
function(spec)
  local required = [
    'name',
  ];
  local optional = {
    finalizer: true,
  };
  assert std.length(std.setDiff(required, std.objectFields(spec))) == 0;
  generate(optional + spec)
