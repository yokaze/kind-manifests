local images = import '../../images.jsonnet';
[{
  kind: 'ReplicaSet',
  apiVersion: 'apps/v1',
  metadata: {
    name: 'sample',
  },
  spec: {
    replicas: 3,
    selector: {
      matchLabels: {
        app: 'sample',
      },
    },
    template: {
      metadata: {
        labels: {
          app: 'sample',
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
