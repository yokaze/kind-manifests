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
        image: 'bitnami/kubectl:1.19.8',
        command: [
          'sleep',
          'inf',
        ],
      },
    ],
  },
}
