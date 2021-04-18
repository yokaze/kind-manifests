[{
  apiVersion: 'monitoring.coreos.com/v1',
  kind: 'ServiceMonitor',
  metadata: {
    name: 'prometheus',
  },
  spec: {
    endpoints: [{
      port: 'web',
    }],
    selector: {
      matchLabels: {
        'operated-prometheus': 'true',
      },
    },
  },
}]
