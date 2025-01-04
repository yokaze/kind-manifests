local apps = import 'apps.jsonnet';
{
  apiVersion: 'kustomize.config.k8s.io/v1beta1',
  kind: 'Kustomization',
  resources: [('%s.yaml' % x.metadata.name) for x in apps],
}
