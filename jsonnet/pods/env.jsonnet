local pod = import '../pod.jsonnet';
local utility = import '../utility.libsonnet';
utility.transform(
  pod, {}, function(p) p + {
    metadata+: {
      name: 'env',
    },
    spec+: {
      containers: utility.transform(
        p.spec.containers,
        {},
        function(c) c + {
          env: [{
            name: 'HELLO',
            value: 'hello',
          }],
        }
      ),
    },
  }
)
