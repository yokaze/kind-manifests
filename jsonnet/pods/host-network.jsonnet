local pod = import '../pod.jsonnet';
local utility = import '../utility.libsonnet';
utility.transform(
  pod, {}, function(p) p + {
    metadata+: {
      name: 'host-network',
    },
    spec+: {
      hostNetwork: true,
    },
  },
)
