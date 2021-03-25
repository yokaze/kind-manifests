{
  "apiVersion": "v1",
  "kind": "ConfigMap",
  "metadata": {
    "name": "promtail"
  },
  "data": {
    "config.yml": importstr "resources/config-audit.yml"
  }
}
