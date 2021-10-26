[{
  apiVersion: 'v1',
  kind: 'Secret',
  metadata: {
    name: 'sample',
  },
  type: 'Opaque',
  data: {
    sample: std.base64('sample'),
  },
}]
