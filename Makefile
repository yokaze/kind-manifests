jsonnet-%:
	@jsonnet $*.jsonnet | yq eval '.[] | splitDoc' - -P

generate-%:
	mkdir -p manifests
	$(MAKE) --no-print-directory jsonnet-$* > manifests/$*.yaml

.PHONY: manifests
manifests:
	$(MAKE) generate-prometheus
	$(MAKE) generate-prometheus-apiserver

.PHONY: prometheus
prometheus: jsonnet-prometheus

.PHONY: prometheus-apiserver
prometheus-apiserver: jsonnet-prometheus-apiserver
