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
        image: 'alpine:3.13.3',
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
