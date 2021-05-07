{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'alpine',
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
      },
    ],
  },
}
