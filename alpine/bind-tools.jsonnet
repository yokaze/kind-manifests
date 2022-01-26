local images = import '../images.jsonnet';
{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'bind-tools',
  },
  spec: {
    containers: [
      {
        name: 'alpine',
        image: images.alpine,
        command: [
          'sh',
          '-c',
          'apk add --no-cache bind-tools && sleep inf',
        ],
      },
    ],
  },
}
