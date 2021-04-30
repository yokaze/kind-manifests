[{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'host-network',
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
    hostNetwork: true,
  },
}]
