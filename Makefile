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

.PHONY: format
format:
	@for i in $(shell find . -name '*.json'); do \
		echo $$i; \
		jq . $$i | sponge $$i; \
	done
	@for i in $(shell find . -name '*.jsonnet'); do \
		echo $$i; \
		jsonnetfmt -i $$i; \
	done

.PHONY: manifests
manifests:
	$(MAKE) generate-alpine
	$(MAKE) generate-grafana
	$(MAKE) generate-grafana-loki
	$(MAKE) generate-host-network
	$(MAKE) generate-kubectl
	$(MAKE) generate-loki
	$(MAKE) generate-mount-configmap
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

.PHONY: mount-configmap
mount-configmap: jsonnet-mount-configmap

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

# Rules for deploying
.PHONY: deploy-prometheus-operator
deploy-prometheus-operator:
	kubectl apply -f upstream/prometheus-operator/bundle.yaml

.PHONY: delete-prometheus-operator
delete-prometheus-operator:
	kubectl delete -f upstream/prometheus-operator/bundle.yaml

# Rules for upstream manifests
PROMETHEUS_OPERATOR_VERSION=0.46.0

.PHONY: clean
clean:
	rm -rf upstream

.PHONY: upstream
upstream: upstream-prometheus-operator

.PHONY: upstream-prometheus-operator
upstream-prometheus-operator:
	mkdir -p upstream/prometheus-operator
	wget -O upstream/prometheus-operator/bundle.yaml https://github.com/prometheus-operator/prometheus-operator/raw/v$(PROMETHEUS_OPERATOR_VERSION)/bundle.yaml
