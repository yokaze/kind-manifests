local waves = {
  cilium: 1,
  'istio-base': 2,
  istio: 3,
  argocd: 4,
  namespaces: 5,
  accurate: 6,
  config: 10000,
};
function(name)
  assert std.objectHas(waves, name) : 'appropriate wave is needed for %s' % name;
  waves[name]
