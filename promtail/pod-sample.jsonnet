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
    initContainers: [
      {
        name: 'generate',
        image: images.bash,
        command: [
          'bash',
          '-c',
          'source /etc/promtail/generate.sh',
        ],
        volumeMounts: [
          {
            name: 'config',
            mountPath: '/etc/promtail',
            readOnly: true,
          },
          {
            name: 'log',
            mountPath: '/var/log',
            readOnly: false,
          },
        ],
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
            mountPath: '/var/log',
            readOnly: false,
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
        emptyDir: {},
      },
    ],
  },
}
