local images = import '../images.jsonnet';
[{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'etcdctl',
  },
  spec: {
    containers: [
      {
        name: 'etcd',
        image: images.etcd,
        command: [
          'sleep',
          'inf',
        ],
      },
    ],
  },
}]
