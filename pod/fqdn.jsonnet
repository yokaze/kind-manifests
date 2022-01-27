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
      hostname: 'sample',
      subdomain: 'sample',
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
    },
    spec: {
      selector: {
        app: 'sample',
      },
      clusterIP: 'None',
      ports: [{
        port: 80,
      }],
    },
  },
]
