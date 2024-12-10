local images = import '../images.jsonnet';
local deploy = import 'deploy.jsonnet';
[std.mergePatch(deploy[0], {
  spec: {
    template: {
      spec: {
        topologySpreadConstraints: [
          {
            maxSkew: 1,
            topologyKey: 'kubernetes.io/hostname',
            whenUnsatisfiable: 'DoNotSchedule',
            labelSelector: {
              matchLabels: {
                app: 'sample',
              },
            },
          },
        ],
      },
    },
  },
})]
