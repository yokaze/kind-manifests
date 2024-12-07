{
  hubble: {
    relay: {
      enabled: true,
    },
  },
  envoy: {
    enabled: false,
  },
  extraConfig: {
    'enable-k8s-networkpolicy': 'false',
  },
  l7Proxy: false,
}
