std.mergePatch(import "pod.json", {
  "spec": {
    "volumes": {
      "configMap": {
        "items": [
          {
            "key": "prometheus.yaml",
            "path": "prometheus.yaml"
          },
          {
            "key": "loki.yaml",
            "path": "loki.yaml"
          }
        ]
      }
    }
  }
})
