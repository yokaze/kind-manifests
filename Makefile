CILIUM_VERSION := 1.16.3
HELM_VERSION ?= $(shell if [ -z "$(HELM_REPO)" ]; then echo latest; else helm show chart $(HELM_REPO) | yq .version; fi)

# Cluster Targets
.PHONY: registry
registry:
	docker run -d --expose 5000 -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io --name=mirror-docker --restart=always registry:2
	docker run -d --expose 5000 -e REGISTRY_PROXY_REMOTEURL=https://ghcr.io --name=mirror-ghcr --restart=always registry:2
	docker run -d --expose 5000 -e REGISTRY_PROXY_REMOTEURL=https://quay.io --name=mirror-quay --restart=always registry:2
	docker network connect kind mirror-docker
	docker network connect kind mirror-ghcr
	docker network connect kind mirror-quay

.PHONY: stop-registry
stop-registry:
	docker stop mirror-docker || true
	docker stop mirror-ghcr || true
	docker stop mirror-quay || true
	docker rm mirror-docker || true
	docker rm mirror-ghcr || true
	docker rm mirror-quay || true

.PHONY: cluster
cluster:
	docker pull quay.io/cilium/cilium:v$(CILIUM_VERSION)
	kind create cluster --config cluster/cluster.yaml
	kind load docker-image quay.io/cilium/cilium:v$(CILIUM_VERSION)
	kubectl create ns istio-system

	kustomize build argocd/generated/cilium/ | kubectl apply -f -
	@$(MAKE) --no-print-directory wait-pods

	kustomize build argocd/generated/istio-base/ | kubectl apply -f -
	@$(MAKE) --no-print-directory wait-pods

	kustomize build argocd/generated/istio/ | kubectl apply -f -
	@$(MAKE) --no-print-directory wait-pods

	kubectl create ns argocd
	kubectl label ns argocd istio-injection=enabled
	kustomize build argocd/generated/argocd/ | kubectl apply -f -
	@$(MAKE) --no-print-directory wait-pods

.PHONY: cluster-audit
cluster-audit: mount
	kind create cluster --config cluster/cluster-audit.yaml
	@$(MAKE) --no-print-directory wait-nodes

.PHONY: stop
stop:
	kind delete cluster

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

# Manifest Targets
.PHONY: format
format:
	@for i in $$(find -name '*.json' | sort); do \
		echo $$i; \
		jq . $$i | sponge $$i; \
	done
	@for i in $$(find -name '*.*sonnet' | sort); do \
		echo $$i; \
		jsonnetfmt --no-use-implicit-plus -i $$i; \
	done

.PHONY: manifests
manifests:
	rm -rf manifests
	@for i in $$(find jsonnet -name '*.jsonnet' | sort); do \
		echo $$i; \
		OUTPUT_FILE=$$(echo $$i | sed 's/jsonnet/manifests/' | sed 's/jsonnet/yaml/'); \
		OUTPUT_DIR=$$(dirname $${OUTPUT_FILE}); \
		mkdir -p $${OUTPUT_DIR}; \
		jsonnet $$i | yq -P '.[] | splitDoc' > $${OUTPUT_FILE}; \
	done

.PHONY: render-apps
render-apps:
	mkdir -p argocd/generated/config
	@for i in $$(find argocd/template -name '*.jsonnet' | sort); do \
		echo $$i; \
		jsonnet $$i | yq -P > argocd/generated/config/$$(basename $$i .jsonnet).yaml; \
	done

.PHONY: render-helm-template
render-helm-template:
	@mkdir -p argocd/generated/$(HELM_NAME)
	@jsonnet helm/$(HELM_NAME).jsonnet | yq -P | helm template $(HELM_NAME) $(HELM_REPO) -n $(HELM_NS) --version $(HELM_VERSION) --values - | yq -o json | jq -c | jq -cn '[inputs]' > /tmp/$(HELM_NAME).json
	@KINDS=$$(cat /tmp/$(HELM_NAME).json | jq -r '.[] | .kind' | sort | uniq | grep -v null); \
	echo $${KINDS} | jq -nR '.resources = [inputs | split(" ") | .[] + ".yaml"]' | yq -P '.apiVersion="kustomize.config.k8s.io/v1beta1" | .kind="Kustomization" | sort_keys(.)' > argocd/generated/$(HELM_NAME)/kustomization.yaml; \
	for i in $${KINDS}; do \
		echo argocd/generated/$(HELM_NAME)/$$i.yaml; \
		cat /tmp/$(HELM_NAME).json | jq "[.[] | select(.kind==\"$$i\")]" | yq -P '.[] | splitDoc' > argocd/generated/$(HELM_NAME)/$$i.yaml; \
	done

.PHONY: render-helm
render-helm:
	@$(MAKE) --no-print-directory HELM_NAME=argocd HELM_REPO=argo/argo-cd HELM_NS=argocd render-helm-template
	@$(MAKE) --no-print-directory HELM_NAME=cilium HELM_REPO=cilium/cilium HELM_NS=kube-system HELM_VERSION=$(CILIUM_VERSION) render-helm-template
	@$(MAKE) --no-print-directory HELM_NAME=istio-base HELM_REPO=istio/base HELM_NS=istio-system render-helm-template
	@$(MAKE) --no-print-directory HELM_NAME=istio HELM_REPO=istio/istiod HELM_NS=istio-system render-helm-template

.PHONY: render
render:
	rm -rf argocd/generated
	@$(MAKE) --no-print-directory render-apps
	@$(MAKE) --no-print-directory render-helm

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

.PHONY: debug-accurate
debug-accurate:
	@$(MAKE) --no-print-directory ensure-cert-manager
	docker build -t accurate:debug debug/
	kind load docker-image accurate:debug
	kustomize build debug --enable-helm | kubectl apply -f -
	while [ "$$(kubectl get -n accurate $$(kubectl get pod -n accurate -l app.kubernetes.io/name=accurate -o name) -o yaml 2>/dev/null | yq e .status.phase -)" != "Running" ]; do sleep 1; done
	kubectl port-forward -n accurate $$(kubectl get pod -n accurate -l app.kubernetes.io/name=accurate -o name) 12345

.PHONY: halt-accurate
halt-accurate:
	kubectl delete validatingwebhookconfiguration accurate-validating-webhook-configuration || true
	kubectl delete ns accurate || true

.PHONY: login-argocd
login-argocd:
	kubectl config set-context --current --namespace argocd
	argocd login --core

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
	jsonnet helm/cert-manager.jsonnet | yq -P | helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --values -
	@$(MAKE) --no-print-directory wait-pods

.PHONY: ensure-cert-manager
ensure-cert-manager:
	if ! kubectl get ns cert-manager > /dev/null 2>&1; then \
		$(MAKE) --no-print-directory deploy-cert-manager; \
	fi

.PHONY: delete-cert-manager
delete-cert-manager:
	helm uninstall cert-manager --namespace cert-manager
	kubectl delete ns cert-manager

.PHONY: deploy-cert-manager-csi-driver-spiffe
deploy-cert-manager-csi-driver-spiffe: ensure-cert-manager
	kubectl apply -f upstream/cert-manager/csi-driver-spiffe/clusterissuer.yaml
	sleep 5
	cmctl approve -n cert-manager $$(kubectl get cr -n cert-manager -oname | cut -d/ -f2)
	jsonnet helm/cert-manager-csi-driver-spiffe.jsonnet | yq -P | helm install cert-manager-csi-driver-spiffe jetstack/cert-manager-csi-driver-spiffe --namespace cert-manager --values -

.PHONY: deploy-contour
deploy-contour:
	helm install contour bitnami/contour --namespace contour --create-namespace
	@$(MAKE) --no-print-directory wait-pods

.PHONY: delete-contour
delete-contour:
	helm uninstall contour --namespace contour
	kubectl delete ns contour

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

.PHONY: deploy-hydra
deploy-hydra:
	jsonnet helm/hydra.jsonnet | yq -P | helm install hydra ory/hydra --namespace hydra-system --create-namespace --values -
	@$(MAKE) --no-print-directory wait-pods

.PHONY: template-hydra
template-hydra:
	jsonnet helm/hydra.jsonnet | yq -P | helm template hydra ory/hydra --namespace hydra-system --values -

.PHONY: deploy-moco
deploy-moco:
	@$(MAKE) --no-print-directory ensure-cert-manager
	kubectl apply -f upstream/moco/moco.yaml
	@$(MAKE) --no-print-directory wait-pods

.PHONY: delete-moco
delete-moco:
	kubectl delete -f upstream/moco/moco.yaml

.PHONY: deploy-neco-admission
deploy-neco-admission: ensure-cert-manager
	kustomize build neco-admission | kubectl apply -f -

.PHONY: delete-neco-admission
delete-neco-admission:
	kustomize build neco-admission | kubectl delete -f -

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

.PHONY: deploy-sealed-secrets
deploy-sealed-secrets:
	helm install sealed-secrets sealed-secrets/sealed-secrets --namespace sealed-secrets --create-namespace
	@$(MAKE) --no-print-directory wait-pods

.PHONY: deploy-spire
deploy-spire:
	helm install spire-crds spire/spire-crds
	jsonnet helm/spire.jsonnet | yq -P | helm install spire spire/spire --values -
	@$(MAKE) --no-print-directory wait-pods

.PHONY: template-spire
template-spire:
	jsonnet helm/spire.jsonnet | yq -P | helm template spire spire/spire --values -

.PHONY: deploy-trust-manager
deploy-trust-manager: ensure-cert-manager
	jsonnet helm/trust-manager.jsonnet | yq -P | helm install trust-manager cert-manager/trust-manager --values -
	@$(MAKE) --no-print-directory wait-pods

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
CSI_DRIVER_SPIFFE_VERSION := 0.8.1
GRAFANA_OPERATOR_VERSION := 3.9.0
MOCO_VERSION := 0.10.5
PROMETHEUS_OPERATOR_VERSION = 0.47.0

.PHONY: setup
setup:
	mkdir -p bin
	wget -qO- https://github.com/cilium/hubble/releases/download/v1.16.3/hubble-linux-amd64.tar.gz | tar xzv -O hubble > bin/hubble
	chmod +x bin/hubble

.PHONY: clean
clean:
	rm -rf bin
	rm -rf manifests
	rm -rf upstream

.PHONY: upstream
upstream: \
	upstream-grafana-operator \
	upstream-jetstack \
	upstream-moco \
	upstream-neco-admission \
	upstream-prometheus-operator
	helm repo add accurate https://cybozu-go.github.io/accurate/
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo add cattage https://cybozu-go.github.io/cattage/
	helm repo add cilium https://helm.cilium.io/
	helm repo add coredns https://coredns.github.io/helm
	helm repo add istio https://istio-release.storage.googleapis.com/charts
	helm repo add jetstack https://charts.jetstack.io
	helm repo add ory https://k8s.ory.sh/helm/charts
	helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
	helm repo add spire https://spiffe.github.io/helm-charts-hardened
	helm repo add hashicorp https://helm.releases.hashicorp.com
	helm repo update

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

.PHONY: upstream-jetstack
upstream-jetstack:
	mkdir -p upstream/cert-manager/csi-driver-spiffe/
	wget -O upstream/cert-manager/csi-driver-spiffe/clusterissuer.yaml https://raw.githubusercontent.com/cert-manager/csi-driver-spiffe/refs/tags/v$(CSI_DRIVER_SPIFFE_VERSION)/deploy/example/clusterissuer.yaml

.PHONY: upstream-moco
upstream-moco:
	mkdir -p upstream/moco
	wget -O upstream/moco/moco.yaml https://github.com/cybozu-go/moco/releases/download/v$(MOCO_VERSION)/moco.yaml

.PHONY: upstream-neco-admission
upstream-neco-admission:
	mkdir -p neco-admission/upstream
	wget -O neco-admission/upstream/manifests.yaml https://raw.githubusercontent.com/cybozu/neco-containers/main/admission/config/webhook/manifests.yaml

.PHONY: upstream-prometheus-operator
upstream-prometheus-operator:
	mkdir -p upstream/prometheus-operator
	wget -O upstream/prometheus-operator/bundle.yaml https://github.com/prometheus-operator/prometheus-operator/raw/v$(PROMETHEUS_OPERATOR_VERSION)/bundle.yaml
