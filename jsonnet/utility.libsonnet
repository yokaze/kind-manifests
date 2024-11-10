local nested_arr(x, keys) =
  if std.length(keys) == 0 then x else nested_arr(x[keys[0]], keys[1:]);
{
  nested(x, path)::
    nested_arr(x, std.split(path, '.')),

  nested_match(x, path, value)::
    self.nested(x, path) == value,

  transform_element(x, pred, func)::
    if std.all(std.map(
      function(kv)
        self.nested_match(x, kv.key, kv.value),
      std.objectKeysValues(pred)
    )) then func(x) else x,

  transform(arr, pred, func)::
    std.map(
      function(x)
        self.transform_element(x, pred, func),
      arr
    ),
}
