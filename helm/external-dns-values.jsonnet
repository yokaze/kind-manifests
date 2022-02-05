{
  crd: {
    create: true,
  },
  publishInternalServices: true,
  provider: 'coredns',
  coredns: {
    etcdEndpoints: 'http://remote-coredns-etcd.remote-coredns:2379',
  },
}
