{
  "apiVersion": "v1",
  "kind": "ConfigMap",
  "metadata": {
    "name": "promtail"
  },
  "data": {
    "config.yml": importstr "resources/sample-config.yml",
    "generate.sh": importstr "resources/sample-generate.sh"
  },
}
