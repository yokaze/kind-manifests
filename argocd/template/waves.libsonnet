local waves = {
  accurate: 5,
  cilium: 1,
  'istio-base': 2,
  istio: 3,
  argocd: 4,
  config: 10000,
};
function(name)
  assert std.objectHas(waves, name): "appropriate wave is needed for %s" % name;
  waves[name]
