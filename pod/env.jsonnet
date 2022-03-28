local images = import '../images.jsonnet';
[{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'sample',
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
        env: [{
          name: 'SAMPLE',
          value: 'hello',
        }],
      },
    ],
  },
}]
