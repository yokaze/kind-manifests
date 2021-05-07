local images = import '../images.jsonnet';
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
        image: images.alpine,
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
