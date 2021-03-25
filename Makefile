mount:
	./mount.sh

umount:
	./umount.sh

jsonnet-%:
	@jsonnet $*.jsonnet | yq eval '.[] | splitDoc' - -P

generate-%:
	mkdir -p manifests
	$(MAKE) --no-print-directory jsonnet-$* > manifests/$*.yaml

.PHONY: manifests
manifests:
	$(MAKE) generate-grafana
	$(MAKE) generate-grafana-loki
	$(MAKE) generate-loki
	$(MAKE) generate-prometheus
	$(MAKE) generate-prometheus-apiserver
	$(MAKE) generate-prometheus-loki
	$(MAKE) generate-prometheus-promtail
	$(MAKE) generate-promtail-audit
	$(MAKE) generate-promtail-sample

.PHONY: grafana
grafana: jsonnet-grafana

.PHONY: grafana-loki
grafana-loki: jsonnet-grafana-loki

.PHONY: loki
loki: jsonnet-loki

.PHONY: prometheus
prometheus: jsonnet-prometheus

.PHONY: prometheus-apiserver
prometheus-apiserver: jsonnet-prometheus-apiserver

.PHONY: prometheus-loki
prometheus-loki: jsonnet-prometheus-loki

.PHONY: prometheus-promtail
prometheus-promtail: jsonnet-prometheus-promtail

.PHONY: promtail-audit
promtail-audit: jsonnet-promtail-audit

.PHONY: promtail-sample
promtail-sample: jsonnet-promtail-sample
