{
  apiVersion: 'moco.cybozu.com/v1beta1',
  kind: 'MySQLCluster',
  metadata: {
    name: 'sample',
  },
  spec: {
    replicas: 3,
    podTemplate: {
      spec: {
        affinity: {
          podAntiAffinity: {
            requiredDuringSchedulingIgnoredDuringExecution: [
              {
                labelSelector: {
                  matchExpressions: [
                    {
                      key: 'app.kubernetes.io/name',
                      operator: 'In',
                      values: [
                        'mysql',
                      ],
                    },
                    {
                      key: 'app.kubernetes.io/instance',
                      operator: 'In',
                      values: [
                        'sample',
                      ],
                    },
                  ],
                },
                topologyKey: 'kubernetes.io/hostname',
              },
            ],
          },
        },
        containers: [
          {
            name: 'mysqld',
            image: 'quay.io/cybozu/moco-mysql:8.0.24',
          },
        ],
      },
    },
    volumeClaimTemplates: [
      {
        metadata: {
          name: 'mysql-data',
        },
        spec: {
          accessModes: [
            'ReadWriteOnce',
          ],
          resources: {
            requests: {
              storage: '1Gi',
            },
          },
        },
      },
    ],
  },
}
