local kustomization = import 'kustomization.libsonnet';
kustomization([
  'loki',
  'pyroscope',
  'victoria-metrics',
])
