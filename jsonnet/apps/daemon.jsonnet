local images = import '../../images.jsonnet';
[{
  apiVersion: 'apps/v1',
  kind: 'DaemonSet',
  metadata: {
    name: 'sample-daemon',
  },
  spec: {
    selector: {
      matchLabels: {
        app: 'sample-daemon',
      },
    },
    template: {
      metadata: {
        labels: {
          app: 'sample-daemon',
        },
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
          },
        ],
      },
    },
  },
}]
