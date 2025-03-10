local configAppName = 'config';
local waves = import 'waves.libsonnet';
local generate = function(spec) {
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    namespace: 'argocd',
    name: spec.name,
    annotations: {
      'argocd.argoproj.io/sync-wave': std.toString(waves.order(spec)),
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
      repoURL: 'git://mirror-git:9418/kind-manifests.git',
      targetRevision: 'main',
      path: 'apps/%s' % spec.name,
    },
  } + (
    if spec.sync then {
      syncPolicy: {
        automated: {
          prune: true,
          selfHeal: true,
        },
      },
    } else {}
  ) + (
    if std.objectHas(spec, 'ignoreDifferences') then {
      ignoreDifferences: spec.ignoreDifferences,
    } else {}
  ),
};
function(spec)
  local required = [
    'name',
  ];
  local optional = {
    finalizer: true,
    sync: true,
  };
  assert std.length(std.setDiff(required, std.objectFields(spec))) == 0 : 'required params are missing';
  generate(optional + spec)
