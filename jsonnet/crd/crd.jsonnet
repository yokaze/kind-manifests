[{
  apiVersion: 'apiextensions.k8s.io/v1',
  kind: 'CustomResourceDefinition',
  metadata: {
    name: 'samples.yokaze.github.io',
  },
  spec: {
    group: 'yokaze.github.io',
    names: {
      plural: 'samples',
      singular: 'sample',
      kind: 'Sample',
    },
    scope: 'Namespaced',
    versions: [
      {
        name: 'v1',
        served: true,
        storage: true,
        schema: {
          openAPIV3Schema: {
            type: 'object',
            properties: {
              spec: {
                type: 'object',
                properties: {
                  message: {
                    type: 'string',
                  },
                  priority: {
                    type: 'integer',
                  },
                },
              },
            },
          },
        },
      },
    ],
  },
}]
