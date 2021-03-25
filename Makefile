.PHONY: prometheus
prometheus:
	@jsonnet prometheus.jsonnet | yq eval '.[] | splitDoc' - -P
