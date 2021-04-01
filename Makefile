# Rules for cluster
.PHONY: cluster
cluster:
	kind create cluster --config cluster/cluster.yaml

.PHONY: mount
mount:
	./mount.sh

.PHONY: umount
umount:
	./umount.sh

# Rules for manifests
jsonnet-%:
	@jsonnet $*.jsonnet | yq eval '.[] | splitDoc' - -P

generate-%:
	mkdir -p manifests
	$(MAKE) --no-print-directory jsonnet-$* > manifests/$*.yaml

.PHONY: manifests
manifests:
	$(MAKE) generate-alpine
	$(MAKE) generate-grafana
	$(MAKE) generate-grafana-loki
	$(MAKE) generate-host-network
	$(MAKE) generate-kubectl
	$(MAKE) generate-loki
	$(MAKE) generate-prometheus
	$(MAKE) generate-prometheus-apiserver
	$(MAKE) generate-prometheus-loki
	$(MAKE) generate-prometheus-promtail
	$(MAKE) generate-promtail-audit
	$(MAKE) generate-promtail-sample

.PHONY: alpine
alpine: jsonnet-alpine

.PHONY: grafana
grafana: jsonnet-grafana

.PHONY: grafana-loki
grafana-loki: jsonnet-grafana-loki

.PHONY: host-network
host-network: jsonnet-host-network

.PHONY: kubectl
kubectl: jsonnet-kubectl

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
