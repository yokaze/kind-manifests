{
  isClusterService: false,
  servers: [{
    port: 53,
    plugins: [
      { name: 'errors' },
      {
        name: 'etcd',
        configBlock: importstr 'resources/remote-coredns-config',
      },
      {
        name: 'health',
        configBlock: 'lameduck 5s',
      },
      { name: 'loadbalance' },
      { name: 'log' },
      { name: 'loop' },
      { name: 'ready' },
    ],
  }],
}
