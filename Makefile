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
	kubectl wait node --all --for condition=Ready
	@$(MAKE) --no-print-directory wait-pods

wait-pods:
	for n in $$(kubectl get ns -o yaml | yq e '.items[].metadata.name' -); do \
		for i in $$(kubectl get deploy -n $$n -o name); do \
			kubectl rollout status -n $$n $$i -w > /dev/null; \
		done; \
	done
	while test "$$(kubectl get pods -A -o yaml | yq e '.items[]|select(.status.conditions[] as $$i ireduce(false; . or ($$i.status != "True")))' -)"; do sleep 1; done
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
	$(MAKE) generate-accurate-gallery
	$(MAKE) generate-alpine
	$(MAKE) generate-argocd-app
	$(MAKE) generate-argocd-app-kustomize
	$(MAKE) generate-bind-tools
	$(MAKE) generate-burstable
	$(MAKE) generate-cluster-first-with-host-net
	$(MAKE) generate-configmap
	$(MAKE) generate-crd
	$(MAKE) generate-crd-resource
	$(MAKE) generate-daemon
	$(MAKE) generate-deploy
	$(MAKE) generate-deploy-tsc
	$(MAKE) generate-etcdctl
	$(MAKE) generate-grafana
	$(MAKE) generate-grafana-basic
	$(MAKE) generate-grafana-loki
	$(MAKE) generate-grafana-operator-grafana
	$(MAKE) generate-grafana-operator-prometheus
	$(MAKE) generate-host-network
	$(MAKE) generate-job
	$(MAKE) generate-kubectl
	$(MAKE) generate-loki
	$(MAKE) generate-moco
	$(MAKE) generate-monitoring
	$(MAKE) generate-mount-configmap
	$(MAKE) generate-ns
	$(MAKE) generate-pdb
	$(MAKE) generate-pod
	$(MAKE) generate-pod-env
	$(MAKE) generate-pod-fqdn
	$(MAKE) generate-prometheus
	$(MAKE) generate-prometheus-apiserver
	$(MAKE) generate-prometheus-loki
	$(MAKE) generate-prometheus-operator-monitor-prometheus
	$(MAKE) generate-prometheus-operator-prometheus
	$(MAKE) generate-prometheus-promtail
	$(MAKE) generate-promtail-audit
	$(MAKE) generate-promtail-sample
	$(MAKE) generate-pvc
	$(MAKE) generate-replica
	$(MAKE) generate-secret
	$(MAKE) generate-sts
	$(MAKE) generate-svc-different-ports
	$(MAKE) generate-svc-external-dns
	$(MAKE) generate-svc-headless

# Rules for deploying
.PHONY: deploy-accurate
deploy-accurate:
	@$(MAKE) --no-print-directory ensure-cert-manager
	helm install accurate accurate/accurate --namespace accurate --create-namespace --values helm/accurate-values.yaml
	@$(MAKE) --no-print-directory wait-pods

.PHONY: delete-accurate
delete-accurate:
	helm uninstall --namespace accurate accurate
	kubectl delete ns accurate

.PHONY: deploy-argocd
deploy-argocd:
	jsonnet helm/argocd-values.jsonnet | yq e . - -P | helm install argocd argo/argo-cd --namespace argocd --create-namespace --values -
	@$(MAKE) --no-print-directory wait-pods

.PHONY: forward-argocd
forward-argocd:
	kubectl port-forward -n argocd service/argocd-server 8080:80

.PHONY: password-argocd
password-argocd:
	kubectl get secret -n argocd argocd-initial-admin-secret -o yaml | yq e .data.password - | base64 -d

.PHONY: login-argocd
login-argocd:
	kubectl port-forward -n argocd service/argocd-server 8080:80 > /dev/null &
	sleep 5
	argocd login localhost:8080 --username admin --password $$(kubectl get secret -n argocd argocd-initial-admin-secret -o yaml | yq e .data.password - | base64 -d)

.PHONY: logout-argocd
logout-argocd:
	argocd logout localhost:8080
	kill $$(pgrep kubectl)

.PHONY: delete-argocd
delete-argocd:
	helm uninstall argocd --namespace argocd
	kubectl delete ns argocd

.PHONY: deploy-cattage
deploy-cattage:
	@$(MAKE) --no-print-directory ensure-cert-manager
	helm install cattage cattage/cattage --namespace cattage --create-namespace
	@$(MAKE) --no-print-directory wait-pods

.PHONY: delete-cattage
delete-cattage:
	helm uninstall cattage --namespace cattage
	kubectl delete ns cattage

.PHONY: deploy-cert-manager
deploy-cert-manager:
	kubectl apply -f upstream/cert-manager/cert-manager.yaml
	@$(MAKE) --no-print-directory wait-pods

.PHONY: delete-cert-manager
delete-cert-manager:
	kubectl delete -f upstream/cert-manager/cert-manager.yaml

.PHONY: ensure-cert-manager
ensure-cert-manager:
	if ! kubectl get ns cert-manager > /dev/null 2>&1; then \
		$(MAKE) --no-print-directory deploy-cert-manager; \
	fi

.PHONY: deploy-external-dns
deploy-external-dns:
	jsonnet helm/external-dns-values.jsonnet | yq e . - -P | helm install external-dns bitnami/external-dns --namespace external-dns --create-namespace --values -
	@$(MAKE) --no-print-directory wait-pods

.PHONY: delete-external-dns
delete-external-dns:
	helm uninstall external-dns --namespace external-dns
	kubectl delete ns external-dns

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
	@$(MAKE) --no-print-directory ensure-cert-manager
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

.PHONY: deploy-remote-coredns
deploy-remote-coredns:
	kubectl create ns remote-coredns
	jsonnet helm/remote-coredns-etcd-values.jsonnet | yq e . - -P | helm install remote-coredns-etcd bitnami/etcd --namespace remote-coredns --values -
	@$(MAKE) --no-print-directory wait-pods
	jsonnet helm/remote-coredns-values.jsonnet | yq e . - -P | helm install remote-coredns coredns/coredns --namespace remote-coredns --values -
	@$(MAKE) --no-print-directory wait-pods

.PHONY: delete-remote-coredns
delete-remote-coredns:
	helm uninstall remote-coredns --namespace remote-coredns
	helm uninstall remote-coredns-etcd --namespace remote-coredns
	kubectl delete ns remote-coredns

.PHONY: deploy-vault
VAULT_CHART_VERSION := 0.18.0

deploy-vault:
	jsonnet helm/vault-values.jsonnet | yq e . - -P | helm install vault hashicorp/vault --version $(VAULT_CHART_VERSION) --namespace vault --create-namespace --values -
	while [ $$(kubectl get sts -n vault vault -o yaml | yq e .status.currentReplicas -) != 3 ]; do sleep 1; done
	kubectl wait -n vault pod/vault-0 pod/vault-1 pod/vault-2 --for condition=Initialized
	jsonnet helm/vault-init.jsonnet | yq e '.[]|splitDoc' - -P | kubectl apply -f -
	kubectl wait -n vault pod/vault-0 pod/vault-1 pod/vault-2 --for condition=Ready

.PHONY: delete-vault
delete-vault:
	jsonnet helm/vault-init.jsonnet | yq e '.[]|splitDoc' - -P | kubectl delete -f -
	helm uninstall vault --namespace vault
	kubectl delete ns vault

# Rules for upstream manifests
ARGOCD_VERSION := 2.1.2
CERT_MANAGER_VERSION := 1.5.3
GRAFANA_OPERATOR_VERSION := 3.9.0
HNC_VERSION := 0.8.0
MOCO_VERSION := 0.10.5
PROMETHEUS_OPERATOR_VERSION = 0.47.0

.PHONY: clean
clean:
	rm -rf manifests
	rm -rf upstream

.PHONY: upstream
upstream: \
	upstream-accurate \
	upstream-argocd \
	upstream-bitnami \
	upstream-cattage \
	upstream-cert-manager \
	upstream-coredns \
	upstream-grafana-operator \
	upstream-hnc \
	upstream-moco \
	upstream-prometheus-operator \
	upstream-vault

.PHONY: upstream-accurate
upstream-accurate:
	helm repo add accurate https://cybozu-go.github.io/accurate/
	helm repo update accurate

.PHONY: upstream-argocd
upstream-argocd:
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update argo

.PHONY: upstream-bitnami
upstream-bitnami:
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update bitnami

.PHONY: upstream-cattage
upstream-cattage:
	helm repo add cattage https://cybozu-go.github.io/cattage/
	helm repo update cattage

.PHONY: upstream-cert-manager
upstream-cert-manager:
	mkdir -p upstream/cert-manager
	wget -O upstream/cert-manager/cert-manager.yaml https://github.com/jetstack/cert-manager/releases/download/v$(CERT_MANAGER_VERSION)/cert-manager.yaml

.PHONY: upstream-coredns
upstream-coredns:
	helm repo add coredns https://coredns.github.io/helm
	helm repo update coredns

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

.PHONY: upstream-vault
upstream-vault:
	helm repo add hashicorp https://helm.releases.hashicorp.com
	helm repo update hashicorp
