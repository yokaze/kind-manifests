{
  app: {
    trustDomain: 'yokaze.github.io',
    issuer: {
      name: 'csi-driver-spiffe-ca',
      kind: 'ClusterIssuer',
      group: 'cert-manager.io',
    },
    runtimeIssuanceConfigMap: '',
  },
}
