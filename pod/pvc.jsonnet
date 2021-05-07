local images = import '../images.jsonnet';
[{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'pvc',
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
    volumes: [
      {
        name: 'vol',
        persistentVolumeClaim: {
          claimName: 'sample',
        },
      },
    ],
  },
}]
