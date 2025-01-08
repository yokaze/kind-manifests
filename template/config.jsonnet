local apps = import 'apps.jsonnet';
local kustomization = import 'kustomization.libsonnet';
kustomization([x.metadata.name for x in apps])
