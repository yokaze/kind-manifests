[{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'cluster-first-with-host-net',
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
    dnsPolicy: 'ClusterFirstWithHostNet',
  },
}]
