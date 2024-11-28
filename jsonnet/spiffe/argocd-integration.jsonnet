local client_script = importstr 'client.sh';
local helper_name = 'integration-helper';
local integration_script = importstr 'argocd-integration-script.sh';
local namespace = 'argocd-integration';
local pod_base = import '../pod.jsonnet';
local utility = import '../utility.libsonnet';
local workload_template = import 'workload-template.libsonnet';
[{
  apiVersion: 'v1',
  kind: 'Namespace',
  metadata: {
    name: namespace,
  },
}, {
  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    namespace: namespace,
    name: helper_name,
  },
  data: {
    script: integration_script,
  },
}, {
  apiVersion: 'v1',
  kind: 'ServiceAccount',
  metadata: {
    namespace: namespace,
    name: helper_name,
  },
}, {
  apiVersion: 'rbac.authorization.k8s.io/v1',
  kind: 'ClusterRoleBinding',
  metadata: {
    namespace: namespace,
    name: helper_name,
  },
  roleRef: {
    apiGroup: 'rbac.authorization.k8s.io',
    kind: 'ClusterRole',
    name: 'cluster-admin',
  },
  subjects: [{
    kind: 'ServiceAccount',
    namespace: namespace,
    name: helper_name,
  }, {
    kind: 'ServiceAccount',
    namespace: namespace,
    name: 'client',
  }],
}] + [pod_base[0] + {
  metadata+: {
    namespace: namespace,
    name: helper_name,
  },
  spec+: {
    containers: [
      pod_base[0].spec.containers[0] + {
        command: ['bash', '-x', '/config/script'],
        volumeMounts+: [{
          name: 'config',
          mountPath: '/config',
        }],
      },
    ],
    serviceAccountName: helper_name,
    volumes+: [{
      name: 'config',
      configMap: {
        name: helper_name,
      },
    }],
  },
}] +
// client
[{
  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    namespace: namespace,
    name: 'client-script',
  },
  data: {
    script: client_script,
  },
}] + utility.transform(
  workload_template(namespace, 'client', 'https://hydra-public.hydra-system/oauth2/token'),
  {
    kind: 'Pod',
    metadata: {
      name: 'client',
    },
  },
  function(r) r + {
    spec+: {
      containers: utility.transform(
        r.spec.containers,
        {
          name: 'ubuntu',
        },
        function(c) c + {
          volumeMounts+: [{
            name: 'script',
            mountPath: '/script',
          }],
        }
      ),
      volumes+: [{
        name: 'script',
        configMap: {
          name: 'client-script',
        },
      }],
    },
  }
)
