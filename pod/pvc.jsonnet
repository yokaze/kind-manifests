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
        image: 'alpine:3.13.3',
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
