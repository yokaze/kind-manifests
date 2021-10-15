local images = import '../images.jsonnet';
[{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'burstable',
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
        resources: {
          requests: {
            cpu: '100m',
            memory: '64Mi',
          },
          limits: {
            cpu: '750m',
            memory: '192Mi',
          },
        },
      },
    ],
  },
}]
