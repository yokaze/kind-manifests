local images = import '../images.jsonnet';
{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'prometheus',
    labels: {
      app: 'prometheus',
    },
  },
  spec: {
    containers: [
      {
        name: 'prometheus',
        image: images.prometheus,
        volumeMounts: [
          {
            name: 'config',
            mountPath: '/etc/prometheus',
            readOnly: true,
          },
        ],
      },
    ],
    volumes: [
      {
        name: 'config',
        configMap: {
          name: 'prometheus',
        },
      },
    ],
  },
}
