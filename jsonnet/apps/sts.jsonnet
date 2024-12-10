local images = import '../../images.jsonnet';
[{
  kind: 'StatefulSet',
  apiVersion: 'apps/v1',
  metadata: {
    name: 'sample',
  },
  spec: {
    serviceName: 'sample',
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
            volumeMounts: [
              {
                name: 'vol',
                mountPath: '/sample',
              },
            ],
          },
        ],
      },
    },
    volumeClaimTemplates: [
      {
        metadata: {
          name: 'vol',
        },
        spec: {
          accessModes: [
            'ReadWriteOnce',
          ],
          resources: {
            requests: {
              storage: '100Mi',
            },
          },
        },
      },
    ],
  },
}]
