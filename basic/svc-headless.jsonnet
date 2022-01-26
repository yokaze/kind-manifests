local images = import '../images.jsonnet';
[
  {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: 'sample',
    },
    spec: {
      replicas: 3,
      selector: {
        matchLabels: {
          app: 'sample',
        },
      },
      template: {
        metadata: {
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
