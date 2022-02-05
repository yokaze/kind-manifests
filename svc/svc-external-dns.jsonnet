local images = import '../images.jsonnet';
[
  {
    apiVersion: 'v1',
    kind: 'Pod',
    metadata: {
      name: 'sample',
      labels: {
        app: 'sample',
      },
    },
    spec: {
      containers: [
        {
          name: 'nginx',
          image: images.nginx,
          ports: [{
            containerPort: 80,
          }],
        },
      ],
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: 'sample',
      annotations: {
        'external-dns.alpha.kubernetes.io/hostname': 'sample.example.com',
      },
    },
    spec: {
      selector: {
        app: 'sample',
      },
      ports: [{
        port: 80,
      }],
    },
  },
]
