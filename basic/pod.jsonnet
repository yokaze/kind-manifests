local images = import '../images.jsonnet';
[{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'alpine',
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
}]
