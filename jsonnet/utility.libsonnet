{
  nested_match(x, pred)::
    if std.isObject(x) then
      std.all(std.map(
        function(kv)
          if std.objectHas(x, kv.key) then
            self.nested_match(x[kv.key], kv.value)
          else
            false
        , std.objectKeysValues(pred)
      ))
    else
      x == pred,

  transform_element(x, pred, func)::
    if self.nested_match(x, pred) then func(x) else x,

  transform(arr, pred, func)::
    std.map(
      function(x)
        self.transform_element(x, pred, func),
      arr
    ),
}
