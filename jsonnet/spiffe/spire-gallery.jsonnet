local workload_template = import 'workload-template.libsonnet';
[{
  apiVersion: 'v1',
  kind: 'Namespace',
  metadata: {
    name: 'spire-sample',
  },
}] + workload_template('spire-sample', 'sample', 'test')
