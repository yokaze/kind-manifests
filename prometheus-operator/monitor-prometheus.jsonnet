[{
  apiVersion: 'monitoring.coreos.com/v1',
  kind: 'ServiceMonitor',
  metadata: {
    name: 'prometheus',
  },
  spec: {
    endpoints: [{
      targetPort: 9090,
    }],
    selector: {
      matchLabels: {
        app: 'prometheus',
      },
    },
  },
}]
