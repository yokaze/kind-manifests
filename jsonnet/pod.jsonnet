local images = import '../images.jsonnet';
[{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'ubuntu',
    annotations: {
      'kubectl.kubernetes.io/default-container': 'ubuntu',
    },
  },
  spec: {
    containers: [
      {
        name: 'ubuntu',
        image: images.ubuntu,
        command: [
          'pause',
        ],
        volumeMounts: [{
          name: 'tmp',
          mountPath: '/tmp',
        }],
      },
    ],
    volumes: [{
      name: 'tmp',
      emptyDir: {},
    }],
  },
}]
