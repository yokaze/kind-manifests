{
  "apiVersion": "v1",
  "kind": "ConfigMap",
  "metadata": {
    "name": "promtail"
  },
  "data": {
    "config.yml": importstr "resources/config-sample.yml",
    "generate.sh": importstr "resources/generate-sample.sh"
  },
}
