local kustomization = import 'kustomization.libsonnet';
local namespaces = import 'namespace-files.jsonnet';
kustomization([x.metadata.name for x in namespaces])
