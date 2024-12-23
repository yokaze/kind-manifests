ROOT_DIR := $(shell pwd)
CILIUM_VERSION := 1.16.4
HELM_VERSION ?= $(shell if [ -z "$(HELM_REPO)" ]; then echo latest; else helm show chart $(HELM_REPO) | yq .version; fi)

# Cluster Targets
.PHONY: registry
registry:
	docker run -d --expose 5000 -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io --name=mirror-docker --restart=always registry:2
	docker run -d --expose 5000 -e REGISTRY_PROXY_REMOTEURL=https://public.ecr.aws --name=mirror-ecr --restart=always registry:2
	docker run -d --expose 5000 -e REGISTRY_PROXY_REMOTEURL=https://ghcr.io --name=mirror-ghcr --restart=always registry:2
	docker run -d --expose 5000 -e REGISTRY_PROXY_REMOTEURL=https://quay.io --name=mirror-quay --restart=always registry:2
	docker network connect kind mirror-docker
	docker network connect kind mirror-ecr
	docker network connect kind mirror-ghcr
	docker network connect kind mirror-quay

.PHONY: stop-registry
stop-registry:
	docker stop mirror-docker || true
	docker stop mirror-ecr || true
	docker stop mirror-ghcr || true
	docker stop mirror-quay || true
	docker rm mirror-docker || true
	docker rm mirror-ecr || true
	docker rm mirror-ghcr || true
	docker rm mirror-quay || true

.PHONY: git
git: sync-git
	docker run -d --name mirror-git --restart=always --mount type=bind,src=$(ROOT_DIR)/mirror-git,dst=/git \
		ghcr.io/cybozu/ubuntu-dev:24.04 bash -c 'git daemon --reuseaddr --verbose --base-path=/git --export-all'
	docker network connect kind mirror-git

.PHONY: sync-git
sync-git:
	sudo rm -rf mirror-git/kind-manifests.git
	mkdir -p mirror-git
	if [ ! -d "mirror-git/kind-manifests.git" ]; then \
		git init --bare -b main mirror-git/kind-manifests.git; \
	fi
	if ! git remote | grep kind > /dev/null; then \
		git remote add kind $(ROOT_DIR)/mirror-git/kind-manifests.git; \
	fi
	git push kind main -f
	sudo chown -R root:root mirror-git/kind-manifests.git

.PHONY: stop-git
stop-git:
	docker stop mirror-git || true
	docker rm mirror-git || true

.PHONY: cluster
cluster: sync-git
	docker pull quay.io/cilium/cilium:v$(CILIUM_VERSION)
	kind create cluster --config cluster/cluster.yaml
	kind load docker-image quay.io/cilium/cilium:v$(CILIUM_VERSION)

	kustomize build argocd/apps/crds | kubectl apply --server-side -f -
	kustomize build argocd/apps/namespaces | kubectl apply -f -
	kustomize build --enable-helm argocd/apps/cilium | kubectl apply -f -
	@$(MAKE) --no-print-directory wait-all

	kustomize build --enable-helm argocd/apps/cert-manager | kubectl apply -f -
	@$(MAKE) --no-print-directory wait-all

	kustomize build --enable-helm argocd/apps/istio-base | kubectl apply -f -
	@$(MAKE) --no-print-directory wait-all

	kustomize build --enable-helm argocd/apps/istio | kubectl apply -f -
	@$(MAKE) --no-print-directory wait-all

#	kubectl label ns argocd istio-injection=enabled
	kustomize build --enable-helm argocd/apps/argocd | kubectl apply -f -
	@$(MAKE) --no-print-directory wait-all

	kustomize build --enable-helm argocd/apps/deck | kubectl apply -f -
	@$(MAKE) --no-print-directory wait-all

	kubectl apply -f argocd/apps/config/config.yaml

	@$(MAKE) login-argocd
	argocd app wait config --health
	argocd app sync config --async $(shell jsonnet argocd/features.jsonnet | jq -r '.[]' | sed 's/^/--resource *:*:/')

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
	@$(MAKE) --no-print-directory wait-all

wait-all:
	kubectl wait deployments -A --all --for condition=Available --timeout=-1s

# Manifest Targets
.PHONY: format
format:
	@for i in $$(find -name '*.json' | grep -v '/charts/' | sort); do \
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
	rm -rf argocd/apps/config
	mkdir -p argocd/apps/config
	@for i in $$(find argocd/template -name '*.jsonnet' | sort); do \
		echo $$i; \
		jsonnet $$i | yq -P > argocd/apps/config/$$(basename $$i .jsonnet).yaml; \
	done

.PHONY: reference-template
reference-template:
	@kustomize build --enable-helm argocd/apps/$(HELM_NAME) | yq '"argocd/reference/" + "\(.metadata.namespace)" + "/" + "\(.kind)" + "/" + "\(.metadata.name).yaml"' | sed 's/\/\//\//' | sort
	@kustomize build --enable-helm argocd/apps/$(HELM_NAME) | yq '"argocd/reference/" + "\(.metadata.namespace)" + "/" + "\(.kind)"' | sort -u | xargs -n1 mkdir -p
	@kustomize build --enable-helm argocd/apps/$(HELM_NAME) | yq --no-doc -s '"argocd/reference/" + "\(.metadata.namespace)" + "/" + "\(.kind)" + "/" + "\(.metadata.name).yaml"'

.PHONY: reference
reference:
	rm -rf argocd/reference
	@$(MAKE) --no-print-directory HELM_NAME=accurate reference-template
	@$(MAKE) --no-print-directory HELM_NAME=approver-policy reference-template
	@$(MAKE) --no-print-directory HELM_NAME=argocd reference-template
	@$(MAKE) --no-print-directory HELM_NAME=cadvisor reference-template
	@$(MAKE) --no-print-directory HELM_NAME=cert-manager reference-template
	@$(MAKE) --no-print-directory HELM_NAME=cilium reference-template
	@$(MAKE) --no-print-directory HELM_NAME=config reference-template
	@$(MAKE) --no-print-directory HELM_NAME=crds reference-template
	@$(MAKE) --no-print-directory HELM_NAME=dashboard reference-template
	@$(MAKE) --no-print-directory HELM_NAME=deck reference-template
	@$(MAKE) --no-print-directory HELM_NAME=grafana reference-template
	@$(MAKE) --no-print-directory HELM_NAME=grafana-operator reference-template
	@$(MAKE) --no-print-directory HELM_NAME=istio reference-template
	@$(MAKE) --no-print-directory HELM_NAME=istio-base reference-template
	@$(MAKE) --no-print-directory HELM_NAME=kube-state-metrics reference-template
	@$(MAKE) --no-print-directory HELM_NAME=namespaces reference-template
	@$(MAKE) --no-print-directory HELM_NAME=node-exporter reference-template
	@$(MAKE) --no-print-directory HELM_NAME=scrape-cadvisor reference-template
	@$(MAKE) --no-print-directory HELM_NAME=scrape-ksm reference-template
	@$(MAKE) --no-print-directory HELM_NAME=scrape-node-exporter reference-template
	@$(MAKE) --no-print-directory HELM_NAME=vm-agent reference-template
	@$(MAKE) --no-print-directory HELM_NAME=vm-cluster reference-template
	@$(MAKE) --no-print-directory HELM_NAME=vm-operator reference-template
	@rm argocd/reference/.yaml

.PHONY: render
render:
	@$(MAKE) --no-print-directory render-apps

.PHONY: waves
waves:
	@for i in $$(find argocd/apps/config -name '*.yaml'); do \
		yq '[.metadata.name, .metadata.annotations."argocd.argoproj.io/sync-wave"] | @tsv' $$i; \
	done | sort -Vk2 | column -t

# Rules for deploying
.PHONY: login-argocd
login-argocd:
	argocd login localhost:30080 --plaintext --username admin --password $$(kubectl get secret -n argocd argocd-initial-admin-secret -oyaml | yq .data.password | base64 -d)

.PHONY: pilot
pilot:
	kubectl exec -it -n deck deploy/pilot -- bash

.PHONY: deploy-cattage
deploy-cattage:
	@$(MAKE) --no-print-directory ensure-cert-manager
	helm install cattage cattage/cattage --namespace cattage --create-namespace
	@$(MAKE) --no-print-directory wait-all

.PHONY: delete-cattage
delete-cattage:
	helm uninstall cattage --namespace cattage
	kubectl delete ns cattage

.PHONY: deploy-cert-manager
deploy-cert-manager:
	jsonnet helm/cert-manager.jsonnet | yq -P | helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --values -
	@$(MAKE) --no-print-directory wait-all

.PHONY: ensure-cert-manager
ensure-cert-manager:
	if ! kubectl get ns cert-manager > /dev/null 2>&1; then \
		$(MAKE) --no-print-directory deploy-cert-manager; \
	fi

.PHONY: deploy-cert-manager-csi-driver-spiffe
deploy-cert-manager-csi-driver-spiffe: ensure-cert-manager
	kubectl apply -f upstream/cert-manager/csi-driver-spiffe/clusterissuer.yaml
	sleep 5
	cmctl approve -n cert-manager $$(kubectl get cr -n cert-manager -oname | cut -d/ -f2)
	jsonnet helm/cert-manager-csi-driver-spiffe.jsonnet | yq -P | helm install cert-manager-csi-driver-spiffe jetstack/cert-manager-csi-driver-spiffe --namespace cert-manager --values -

.PHONY: deploy-contour
deploy-contour:
	helm install contour bitnami/contour --namespace contour --create-namespace
	@$(MAKE) --no-print-directory wait-all

.PHONY: delete-contour
delete-contour:
	helm uninstall contour --namespace contour
	kubectl delete ns contour

.PHONY: deploy-external-dns
deploy-external-dns:
	jsonnet helm/external-dns-values.jsonnet | yq e . - -P | helm install external-dns bitnami/external-dns --namespace external-dns --create-namespace --values -
	@$(MAKE) --no-print-directory wait-all

.PHONY: delete-external-dns
delete-external-dns:
	helm uninstall external-dns --namespace external-dns
	kubectl delete ns external-dns

.PHONY: deploy-hydra
deploy-hydra:
	jsonnet helm/hydra.jsonnet | yq -P | helm install hydra ory/hydra --namespace hydra-system --create-namespace --values -
	@$(MAKE) --no-print-directory wait-all

.PHONY: template-hydra
template-hydra:
	jsonnet helm/hydra.jsonnet | yq -P | helm template hydra ory/hydra --namespace hydra-system --values -

.PHONY: deploy-moco
deploy-moco:
	@$(MAKE) --no-print-directory ensure-cert-manager
	kubectl apply -f upstream/moco/moco.yaml
	@$(MAKE) --no-print-directory wait-all

.PHONY: delete-moco
delete-moco:
	kubectl delete -f upstream/moco/moco.yaml

.PHONY: deploy-neco-admission
deploy-neco-admission: ensure-cert-manager
	kustomize build neco-admission | kubectl apply -f -

.PHONY: delete-neco-admission
delete-neco-admission:
	kustomize build neco-admission | kubectl delete -f -

.PHONY: deploy-remote-coredns
deploy-remote-coredns:
	kubectl create ns remote-coredns
	jsonnet helm/remote-coredns-etcd-values.jsonnet | yq e . - -P | helm install remote-coredns-etcd bitnami/etcd --namespace remote-coredns --values -
	@$(MAKE) --no-print-directory wait-all
	jsonnet helm/remote-coredns-values.jsonnet | yq e . - -P | helm install remote-coredns coredns/coredns --namespace remote-coredns --values -
	@$(MAKE) --no-print-directory wait-all

.PHONY: delete-remote-coredns
delete-remote-coredns:
	helm uninstall remote-coredns --namespace remote-coredns
	helm uninstall remote-coredns-etcd --namespace remote-coredns
	kubectl delete ns remote-coredns

.PHONY: deploy-sealed-secrets
deploy-sealed-secrets:
	helm install sealed-secrets sealed-secrets/sealed-secrets --namespace sealed-secrets --create-namespace
	@$(MAKE) --no-print-directory wait-all

.PHONY: deploy-spire
deploy-spire:
	helm install spire-crds spire/spire-crds
	jsonnet helm/spire.jsonnet | yq -P | helm install spire spire/spire --values -
	@$(MAKE) --no-print-directory wait-all

.PHONY: template-spire
template-spire:
	jsonnet helm/spire.jsonnet | yq -P | helm template spire spire/spire --values -

.PHONY: deploy-trust-manager
deploy-trust-manager: ensure-cert-manager
	jsonnet helm/trust-manager.jsonnet | yq -P | helm install trust-manager cert-manager/trust-manager --values -
	@$(MAKE) --no-print-directory wait-all

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
MOCO_VERSION := 0.10.5

.PHONY: setup
setup:
	mkdir -p bin
	cp $$(aqua which argocd) bin/argocd
	cp $$(aqua which cilium) bin/cilium
	cp $$(aqua which kubectl) bin/kubectl
	cp $$(aqua which yq) bin/yq
	wget -qO- https://github.com/cilium/hubble/releases/download/v$(CILIUM_VERSION)/hubble-linux-amd64.tar.gz | tar xzv -O hubble > bin/hubble
	chmod +x bin/hubble

.PHONY: clean
clean:
	rm -rf bin
	rm -rf manifests
	rm -rf upstream

.PHONY: upstream
upstream: \
	upstream-jetstack \
	upstream-moco \
	upstream-neco-admission
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
