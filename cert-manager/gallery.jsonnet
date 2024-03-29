[
  {
    apiVersion: 'cert-manager.io/v1',
    kind: 'ClusterIssuer',
    metadata: {
      name: 'cluster-selfsign',
    },
    spec: {
      selfSigned: {},
    },
  },
  {
    apiVersion: 'cert-manager.io/v1',
    kind: 'ClusterIssuer',
    metadata: {
      name: 'cluster-ca',
    },
    spec: {
      ca: {
        secretName: 'cluster-ca',
      },
    },
  },
  {
    apiVersion: 'cert-manager.io/v1',
    kind: 'Certificate',
    metadata: {
      namespace: 'cert-manager',
      name: 'cluster-ca',
    },
    spec: {
      commonName: 'cluster-ca',
      duration: '87600h',
      isCA: true,
      issuerRef: {
        kind: 'ClusterIssuer',
        name: 'cluster-selfsign',
      },
      secretName: 'cluster-ca',
      usages: [
        'digital signature',
        'key encipherment',
        'cert sign',
      ],
    },
  },
]
