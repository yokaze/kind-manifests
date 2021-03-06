# Rules for cluster
.PHONY: cluster
cluster:
	kind create cluster --config cluster/cluster.yaml
	@$(MAKE) --no-print-directory wait-nodes

.PHONY: cluster-audit
cluster-audit: mount
	kind create cluster --config cluster/cluster-audit.yaml
	@$(MAKE) --no-print-directory wait-nodes

.PHONY: cluster-ipvs
cluster-ipvs:
	kind create cluster --config cluster/cluster-ipvs.yaml
	@$(MAKE) --no-print-directory wait-nodes

.PHONY: mount
mount:
	./mount.sh

.PHONY: umount
umount:
	./umount.sh

wait-nodes:
	while ! kubectl get nodes > /dev/null 2>&1; do sleep 1; done
	while test "$$(kubectl get nodes -o yaml | yq e '.items[]|.status.conditions[-1]|select(.type != "Ready" or .status != "True")' -)"; do sleep 1; done
	@$(MAKE) --no-print-directory wait-pods

wait-pods:
	for n in $$(kubectl get ns -o yaml | yq e '.items[].metadata.name' -); do \
		for i in $$(kubectl get deploy -n $$n -o name); do \
			kubectl rollout status -n $$n $$i -w > /dev/null; \
		done; \
	done
	while test "$$(kubectl get pods -A -o yaml | yq e '.items[]|select(.status.containerStatuses[] as $$i ireduce(false; . or ($$i.ready == false)))' -)"; do sleep 1; done

# Rules for manifests
jsonnet-%:
	@jsonnet jsonnet/$*.jsonnet | yq eval '.[] | splitDoc' - -P

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
	$(MAKE) generate-cluster-first-with-host-net
	$(MAKE) generate-grafana
	$(MAKE) generate-grafana-basic
	$(MAKE) generate-grafana-loki
	$(MAKE) generate-grafana-operator-grafana
	$(MAKE) generate-grafana-operator-prometheus
	$(MAKE) generate-host-network
	$(MAKE) generate-kubectl
	$(MAKE) generate-loki
	$(MAKE) generate-moco
	$(MAKE) generate-monitoring
	$(MAKE) generate-mount-configmap
	$(MAKE) generate-prometheus
	$(MAKE) generate-prometheus-apiserver
	$(MAKE) generate-prometheus-loki
	$(MAKE) generate-prometheus-operator-monitor-prometheus
	$(MAKE) generate-prometheus-operator-prometheus
	$(MAKE) generate-prometheus-promtail
	$(MAKE) generate-promtail-audit
	$(MAKE) generate-promtail-sample
	$(MAKE) generate-pvc

.PHONY: alpine
alpine: jsonnet-alpine

.PHONY: cluster-first-with-host-net
cluster-first-with-host-net: jsonnet-cluster-first-with-host-net

.PHONY: grafana
grafana: jsonnet-grafana

.PHONY: grafana-basic
grafana-basic: jsonnet-grafana-basic

.PHONY: grafana-loki
grafana-loki: jsonnet-grafana-loki

.PHONY: grafana-operator-grafana
grafana-operator-grafana: jsonnet-grafana-operator-grafana

.PHONY: grafana-operator-prometheus
grafana-operator-prometheus: jsonnet-grafana-operator-prometheus

.PHONY: host-network
host-network: jsonnet-host-network

.PHONY: kubectl
kubectl: jsonnet-kubectl

.PHONY: loki
loki: jsonnet-loki

.PHONY: moco
moco: jsonnet-moco

.PHONY: monitoring
monitoring: jsonnet-monitoring

.PHONY: mount-configmap
mount-configmap: jsonnet-mount-configmap

.PHONY: prometheus
prometheus: jsonnet-prometheus

.PHONY: prometheus-apiserver
prometheus-apiserver: jsonnet-prometheus-apiserver

.PHONY: prometheus-loki
prometheus-loki: jsonnet-prometheus-loki

.PHONY: prometheus-operator-monitor-prometheus
prometheus-operator-monitor-prometheus: jsonnet-prometheus-operator-monitor-prometheus

.PHONY: prometheus-operator-prometheus
prometheus-operator-prometheus: jsonnet-prometheus-operator-prometheus

.PHONY: prometheus-promtail
prometheus-promtail: jsonnet-prometheus-promtail

.PHONY: promtail-audit
promtail-audit: jsonnet-promtail-audit

.PHONY: promtail-sample
promtail-sample: jsonnet-promtail-sample

.PHONY: pvc
pvc: jsonnet-pvc

# Rules for deploying
.PHONY: deploy-cert-manager
deploy-cert-manager:
	kubectl apply -f upstream/cert-manager/cert-manager.yaml
	@$(MAKE) --no-print-directory wait-pods

.PHONY: delete-cert-manager
delete-cert-manager:
	kubectl delete -f upstream/cert-manager/cert-manager.yaml

.PHONY: deploy-grafana-operator
deploy-grafana-operator:
	kubectl apply -f upstream/grafana-operator/cluster_roles/cluster_role_aggregate_grafana_admin_edit.yaml
	kubectl apply -f upstream/grafana-operator/cluster_roles/cluster_role_aggregate_grafana_view.yaml
	kubectl apply -f upstream/grafana-operator/cluster_roles/cluster_role_binding_grafana_operator.yaml
	kubectl apply -f upstream/grafana-operator/cluster_roles/cluster_role_grafana_operator.yaml
	kubectl apply -f upstream/grafana-operator/crds/Grafana.yaml
	kubectl apply -f upstream/grafana-operator/crds/GrafanaDashboard.yaml
	kubectl apply -f upstream/grafana-operator/crds/GrafanaDataSource.yaml
	kubectl apply -f upstream/grafana-operator/roles/role.yaml
	kubectl apply -f upstream/grafana-operator/roles/role_binding.yaml
	kubectl apply -f upstream/grafana-operator/roles/service_account.yaml
	kubectl apply -f upstream/grafana-operator/operator.yaml
	@$(MAKE) --no-print-directory wait-pods

.PHONY: delete-grafana-operator
delete-grafana-operator:
	kubectl delete -f upstream/grafana-operator/cluster_roles/cluster_role_aggregate_grafana_admin_edit.yaml
	kubectl delete -f upstream/grafana-operator/cluster_roles/cluster_role_aggregate_grafana_view.yaml
	kubectl delete -f upstream/grafana-operator/cluster_roles/cluster_role_binding_grafana_operator.yaml
	kubectl delete -f upstream/grafana-operator/cluster_roles/cluster_role_grafana_operator.yaml
	kubectl delete -f upstream/grafana-operator/crds/Grafana.yaml
	kubectl delete -f upstream/grafana-operator/crds/GrafanaDashboard.yaml
	kubectl delete -f upstream/grafana-operator/crds/GrafanaDataSource.yaml
	kubectl delete -f upstream/grafana-operator/roles/role.yaml
	kubectl delete -f upstream/grafana-operator/roles/role_binding.yaml
	kubectl delete -f upstream/grafana-operator/roles/service_account.yaml
	kubectl delete -f upstream/grafana-operator/operator.yaml

.PHONY: deploy-hnc
deploy-hnc:
	kubectl apply -f upstream/hnc/hnc-manager.yaml

.PHONY: delete-hnc
delete-hnc:
	kubectl delete -f upstream/hnc/hnc-manager.yaml

.PHONY: deploy-moco
deploy-moco:
	kubectl apply -f upstream/moco/moco.yaml
	@$(MAKE) --no-print-directory wait-pods

.PHONY: delete-moco
delete-moco:
	kubectl delete -f upstream/moco/moco.yaml

.PHONY: deploy-prometheus-operator
deploy-prometheus-operator:
	kubectl apply -f upstream/prometheus-operator/bundle.yaml
	@$(MAKE) --no-print-directory wait-pods

.PHONY: delete-prometheus-operator
delete-prometheus-operator:
	kubectl delete -f upstream/prometheus-operator/bundle.yaml

# Rules for upstream manifests
CERT_MANAGER_VERSION := 1.3.1
GRAFANA_OPERATOR_VERSION := 3.9.0
HNC_VERSION := 0.8.0
MOCO_VERSION := 0.8.1
PROMETHEUS_OPERATOR_VERSION = 0.47.0

.PHONY: clean
clean:
	rm -rf manifests
	rm -rf upstream

.PHONY: upstream
upstream: \
	upstream-cert-manager \
	upstream-grafana-operator \
	upstream-hnc \
	upstream-moco \
	upstream-prometheus-operator

.PHONY: upstream-cert-manager
upstream-cert-manager:
	mkdir -p upstream/cert-manager
	wget -O upstream/cert-manager/cert-manager.yaml https://github.com/jetstack/cert-manager/releases/download/v$(CERT_MANAGER_VERSION)/cert-manager.yaml

.PHONY: upstream-grafana-operator
upstream-grafana-operator: URL := https://raw.githubusercontent.com/integr8ly/grafana-operator/v$(GRAFANA_OPERATOR_VERSION)/deploy
upstream-grafana-operator:
	mkdir -p upstream/grafana-operator/cluster_roles
	mkdir -p upstream/grafana-operator/crds
	mkdir -p upstream/grafana-operator/roles
	wget -O upstream/grafana-operator/cluster_roles/cluster_role_aggregate_grafana_admin_edit.yaml $(URL)/cluster_roles/cluster_role_aggregate_grafana_admin_edit.yaml
	wget -O upstream/grafana-operator/cluster_roles/cluster_role_aggregate_grafana_view.yaml $(URL)/cluster_roles/cluster_role_aggregate_grafana_view.yaml
	wget -O upstream/grafana-operator/cluster_roles/cluster_role_binding_grafana_operator.yaml $(URL)/cluster_roles/cluster_role_binding_grafana_operator.yaml
	wget -O upstream/grafana-operator/cluster_roles/cluster_role_grafana_operator.yaml $(URL)/cluster_roles/cluster_role_grafana_operator.yaml
	wget -O upstream/grafana-operator/crds/Grafana.yaml $(URL)/crds/Grafana.yaml
	wget -O upstream/grafana-operator/crds/GrafanaDashboard.yaml $(URL)/crds/GrafanaDashboard.yaml
	wget -O upstream/grafana-operator/crds/GrafanaDataSource.yaml $(URL)/crds/GrafanaDataSource.yaml
	wget -O upstream/grafana-operator/roles/role.yaml $(URL)/roles/role.yaml
	wget -O upstream/grafana-operator/roles/role_binding.yaml $(URL)/roles/role_binding.yaml
	wget -O upstream/grafana-operator/roles/service_account.yaml $(URL)/roles/service_account.yaml
	wget -O upstream/grafana-operator/operator.yaml $(URL)/operator.yaml

.PHONY: upstream-hnc
upstream-hnc:
	mkdir -p upstream/hnc
	wget -O upstream/hnc/hnc-manager.yaml https://github.com/kubernetes-sigs/multi-tenancy/releases/download/hnc-v$(HNC_VERSION)/hnc-manager.yaml

.PHONY: upstream-moco
upstream-moco:
	mkdir -p upstream/moco
	wget -O upstream/moco/moco.yaml https://github.com/cybozu-go/moco/releases/download/v$(MOCO_VERSION)/moco.yaml

.PHONY: upstream-prometheus-operator
upstream-prometheus-operator:
	mkdir -p upstream/prometheus-operator
	wget -O upstream/prometheus-operator/bundle.yaml https://github.com/prometheus-operator/prometheus-operator/raw/v$(PROMETHEUS_OPERATOR_VERSION)/bundle.yaml
