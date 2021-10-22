local images = import '../images.jsonnet';
{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'promtail',
    labels: {
      app: 'promtail',
    },
  },
  spec: {
    nodeSelector: {
      'kubernetes.io/hostname': 'kind-control-plane',
    },
    tolerations: [
      {
        key: 'node-role.kubernetes.io/master',
        operator: 'Exists',
        effect: 'NoSchedule',
      },
    ],
    containers: [
      {
        name: 'promtail',
        image: images.promtail,
        volumeMounts: [
          {
            name: 'config',
            mountPath: '/etc/promtail',
            readOnly: true,
          },
          {
            name: 'log',
            mountPath: '/var/log/kube-apiserver',
            readOnly: true,
          },
        ],
      },
    ],
    volumes: [
      {
        name: 'config',
        configMap: {
          name: 'promtail',
        },
      },
      {
        name: 'log',
        hostPath: {
          path: '/var/log/kube-apiserver',
        },
      },
    ],
  },
}
