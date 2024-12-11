local waves = {
  cilium: 1,
  'istio-base': 2,
  istio: 3,
  argocd: 4,
  config: 10000,
};
function(name)
  assert std.objectHas(waves, name);
  waves[name]
