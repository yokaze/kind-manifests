local images = import '../images.jsonnet';
{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'loki',
    labels: {
      app: 'loki',
    },
  },
  spec: {
    containers: [
      {
        name: 'loki',
        image: images.loki,
      },
    ],
  },
}
