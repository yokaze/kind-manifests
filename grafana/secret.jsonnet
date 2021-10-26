{
  apiVersion: 'v1',
  kind: 'Secret',
  metadata: {
    name: 'grafana',
  },
  type: 'Opaque',
  data: {
    username: std.base64('admin'),
    password: std.base64('password'),
  },
}
