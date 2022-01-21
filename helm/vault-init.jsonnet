local images = import '../images.jsonnet';
[
  {
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      name: 'vault-init',
    },
  },
  {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      namespace: 'vault-init',
      name: 'vault-init',
    },
    data: {
      'vault-init.sh': importstr 'resources/vault-init.sh',
    },
  },
  {
    apiVersion: 'batch/v1',
    kind: 'Job',
    metadata: {
      namespace: 'vault-init',
      name: 'vault-init',
    },
    spec: {
      template: {
        spec: {
          containers: [{
            name: 'init',
            image: images.vault,
            command: ['sh', '-c', '. /etc/vault-init/vault-init.sh'],
            volumeMounts: [{
              name: 'vault-init',
              mountPath: '/etc/vault-init',
              readOnly: true,
            }],
          }],
          volumes: [{
            name: 'vault-init',
            configMap: {
              name: 'vault-init',
            },
          }],
          restartPolicy: 'OnFailure',
        },
      },
    },
  },
]
