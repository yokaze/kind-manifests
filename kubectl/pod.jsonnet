local images = import '../images.jsonnet';
{
  kind: 'Pod',
  apiVersion: 'v1',
  metadata: {
    name: 'kubectl',
  },
  spec: {
    serviceAccountName: 'kubectl',
    containers: [
      {
        name: 'kubectl',
        image: images.kubectl,
        command: [
          'sleep',
          'inf',
        ],
      },
    ],
  },
}
