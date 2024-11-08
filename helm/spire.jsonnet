{
  global: {
    spire: {
      recommendations: {
        enabled: true,
      },
      namespaces: {
        create: true,
      },
      clusterName: 'k8s',
      trustDomain: 'yokaze.github.io',
      caSubject: {
        country: 'JP',
        organization: 'stella',
        commonName: 'yokaze.github.io',
      },
    },
  },
  controllerManager: {
    identities: {
      clusterSPIFFEIDs: {
        'test-keys': {
          enabled: false,
        },
      },
    },
  },
}
