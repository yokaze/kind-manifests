local images = import '../images.jsonnet';
{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'sample',
  },
  spec: {
    containers: [
      {
        name: 'alpine',
        image: images.alpine,
        command: [
          'sleep',
          'inf',
        ],
        volumeMounts: [
          {
            name: 'sample',
            mountPath: '/etc/sample',
            readOnly: true,
          },
        ],
      },
    ],
    volumes: [
      {
        name: 'sample',
        configMap: {
          name: 'sample',
        },
      },
    ],
  },
}
