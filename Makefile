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
cluster: sync-git stop
	docker pull quay.io/cilium/cilium:v$(CILIUM_VERSION)
	kind create cluster --config cluster/cluster.yaml
	kind load docker-image quay.io/cilium/cilium:v$(CILIUM_VERSION)

	ARGOCD_WAVE=$$($(MAKE) --no-print-directory waves | grep -e '^argocd\s' | awk '{print $$2}'); \
	for i in $$(seq $${ARGOCD_WAVE}); do \
		echo; \
		echo "WAVE $$i"; \
		for j in $$($(MAKE) --no-print-directory waves | grep -Fw $$i | awk '{print $$1}'); do \
			kustomize build --enable-helm apps/$$j | kubectl apply $$(if [ "$$j" = "crds" ]; then echo --server-side; fi) -f -; \
		done; \
		if [ $$i -ge 2 ]; then \
			$(MAKE) --no-print-directory wait-all; \
		fi; \
	done; \
	echo

	kubectl apply -f apps/config/config.yaml

	@$(MAKE) login-argocd
	argocd app wait config --health
	argocd app sync config $(shell jsonnet template/features.jsonnet | jq -r '.apps[]' | sed 's/^/--resource *:*:/')
	@$(MAKE) --no-print-directory wait-all
	@echo
	if [ $$(jsonnet template/features.jsonnet | jq '.datasources | length') -gt 0 ]; then \
		argocd app sync datasource $(shell jsonnet template/features.jsonnet | jq -r '.datasources[]' | sed 's/^/--resource *:*:/'); \
	fi
	@echo
	if [ $$(jsonnet template/features.jsonnet | jq '.scrapes | length') -gt 0 ]; then \
		argocd app sync scrape $(shell jsonnet template/features.jsonnet | jq -r '.scrapes[]' | awk '{ printf("--resource *:*:%s/*\n", $$1) }'); \
	fi
	@echo

.PHONY: stop
stop:
	kind delete cluster

.PHONY: wait-nodes
wait-nodes:
	while ! kubectl get nodes > /dev/null 2>&1; do sleep 1; done
	kubectl wait node --all --for condition=Ready
	@$(MAKE) --no-print-directory wait-all

.PHONY: wait-all
wait-all:
	kubectl wait deployments -A --all --for condition=Available --timeout=-1s

.PHONY: rollout
rollout:
	@for n in $$(kubectl get node -oname | cut -d/ -f2); do \
		kubectl drain --ignore-daemonsets --delete-emptydir-data $$n; \
		kubectl uncordon $$n; \
	done

.PHONY: rollout-all
rollout-all:
	@for n in $$(kubectl get node -oname | cut -d/ -f2); do \
		kubectl drain --ignore-daemonsets --delete-emptydir-data $$n; \
		for p in $$(kubectl get po --field-selector spec.nodeName=$$n -Aojson | jq -r '.items[].metadata | select(.ownerReferences[0].kind == "DaemonSet") | "\(.namespace)/\(.name)"'); do \
			kubectl delete pod --wait=false -n $$(echo $$p | cut -d/ -f1) $$(echo $$p | cut -d/ -f2); \
		done; \
		kubectl uncordon $$n; \
	done

.PHONY: images
images:
	@{ \
		kubectl get po -Aojson | jq -r '.items[].spec.initContainers[]?.image'; \
		kubectl get po -Aojson | jq -r '.items[].spec.containers[].image'; \
	} | sort -u

.PHONY: scrape
scrape:
	kubectl exec -n deck deploy/pilot -- curl -s http://vmagent-vm-agent.victoria-metrics.svc:8429/targets

.PHONY: metrics
metrics:
	@JOBS=$$(kubectl exec -n deck deploy/pilot -- curl -s http://vmselect-vm-cluster.victoria-metrics:8481/select/0/prometheus/api/v1/label/job/values | jq -r '.data[]'); \
	for i in $${JOBS}; do \
		echo $$i:; \
		kubectl exec -n deck deploy/pilot -- curl -s http://vmselect-vm-cluster.victoria-metrics:8481/select/0/prometheus/api/v1/label/__name__/values -d "match[]={job=\"$$i\"}" | jq -r '.data[]' | sed 's/^/- /'; \
	done | yq

.PHONY: logs
logs:
	@stern . -A --max-log-requests 100 \
		-e '(^|\s)I\d+\s' \
		-e 'level=(info|INFO|debug)' \
		-e '\"info\"' \
		-e '\s(info|INFO)\s' \
		-e '\[(info|INFO)\]'

# Manifest Targets
.PHONY: format
format:
	@for i in $$(git ls-files | grep -e '[.]json$$' | sort); do \
		echo $$i; \
		jq . $$i | sponge $$i; \
	done
	@for i in $$(git ls-files | grep -e '[.].*sonnet$$' | sort); do \
		echo $$i; \
		jsonnetfmt --no-use-implicit-plus -i $$i; \
	done
	@for i in $$(git ls-files | grep -e '[.]yaml$$' | grep -v 'aqua.yaml' | sort); do \
		echo $$i; \
		yq -iP $$i; \
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

.PHONY: config
config:
	rm -rf apps/config
	mkdir -p apps/config
	jsonnet template/apps.jsonnet | yq '.[] | splitDoc' -P | yq --no-doc -s '"apps/config/" + "\(.metadata.name).yaml"'
	jsonnet template/config.jsonnet | yq -P > apps/config/kustomization.yaml
	jsonnet template/datasource.jsonnet | yq -P > apps/datasource/kustomization.yaml
	jsonnet template/scrape.jsonnet | yq -P > apps/scrape/kustomization.yaml

.PHONY: reference-template
reference-template:
	@kustomize build --enable-helm apps/$(HELM_NAME) | yq '"reference/" + "\(.metadata.namespace)" + "/" + "\(.kind)" + "/" + "\(.metadata.name).yaml"' | sed 's/\/\//\//' | sort
	@kustomize build --enable-helm apps/$(HELM_NAME) | yq '"reference/" + "\(.metadata.namespace)" + "/" + "\(.kind)"' | sort -u | xargs -n1 mkdir -p
	@kustomize build --enable-helm apps/$(HELM_NAME) | yq --no-doc -s '"reference/" + "\(.metadata.namespace)" + "/" + "\(.kind)" + "/" + "\(.metadata.name).yaml"'

.PHONY: reference
reference:
	@rm -rf reference
	@for i in $$(jsonnet template/apps.jsonnet | jq -r '.[].metadata.name'); do \
		$(MAKE) --no-print-directory HELM_NAME=$$i reference-template; \
		echo; \
	done

.PHONY: resources
resources:
	@for i in $$(jsonnet template/apps.jsonnet | jq -r '.[].metadata.name'); do \
		kustomize build --enable-helm apps/$$i | yq '[.metadata.annotations."argocd.argoproj.io/sync-wave" // 0, .kind, .metadata.namespace, .metadata.name] | @tsv' | sed "s/^/$$i /" | sort -nk2 | column -t; \
		echo; \
	done

.PHONY: features
features:
	@jsonnet template/features.jsonnet | yq -P

.PHONY: waves
waves:
	@for i in $$(find apps/config -name '*.yaml' | grep -v 'kustomization.yaml'); do \
		yq '[.metadata.name, .metadata.annotations."argocd.argoproj.io/sync-wave"] | @tsv' $$i; \
	done | sort -Vk2 | column -t

# Rules for deploying
.PHONY: login-argocd
login-argocd:
	argocd login localhost:30080 --plaintext --username admin --password $$(kubectl get secret -n argocd argocd-initial-admin-secret -oyaml | yq .data.password | base64 -d)

.PHONY: pilot
pilot:
	kubectl exec -it -n deck deploy/pilot -- bash

.PHONY: pid
pid:
	@{ echo NAMESPACE NAME CONTAINER NODE HOST-PID PID; \
	{ for n in $$(kubectl get node -oname | cut -d/ -f2); do \
		INFO=$$(for c in $$(docker exec $$n crictl ps -o json | jq -r '.containers[].id'); do \
			docker exec $$n crictl inspect $$c | jq '{ "labels": .status.labels, "pid": .info.pid }'; \
		done | jq -cs); \
		PROCS=$$(for p in $$(docker top $$n -eo pid | tail -n +2); do \
			cat /proc/$$p/status | grep NSpid | awk '{ printf("[%s, %s]\n", $$2, $$3) }'; \
		done | jq -cs); \
		for i in $$(echo $${INFO} | jq -c .[]); do \
			echo $$(echo $$i | jq -r '.labels | [."io.kubernetes.pod.namespace", ."io.kubernetes.pod.name", ."io.kubernetes.container.name"] | @tsv') \
				$$n $$(echo $${PROCS} | jq -c '.[]' | grep -Fw $$(echo $$i | jq -r '.pid') | jq -r '.[:2] | @tsv'); \
		done; \
	done; } | sort; } | column -t

.PHONY: istio-ns
istio-ns:
	@kubectl get ns -ojson | jq -r '.items[].metadata | select(.labels."istio-injection" == "enabled") | .name'

.PHONY: outbound-http
outbound-http:
	 sudo tshark -i eth0 -Y http

.PHONY: outbound-tls
outbound-tls:
	sudo tshark -i eth0 -Y tls.handshake

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
	mkdir -p node/deck
	cp $$(aqua which argocd) node/deck/argocd
	cp $$(aqua which cilium) node/deck/cilium
	cp $$(aqua which kubectl) node/deck/kubectl
	cp $$(aqua which stern) node/deck/stern
	cp $$(aqua which yq) node/deck/yq
	wget -qO- https://github.com/cilium/hubble/releases/download/v$(CILIUM_VERSION)/hubble-linux-amd64.tar.gz | tar xzv -O hubble > node/deck/hubble
	chmod +x node/deck/hubble

.PHONY: clean
clean:
	rm -rf bin
	rm -rf manifests
	rm -rf upstream

.PHONY: upstream
upstream: \
	upstream-jetstack \
	upstream-moco
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
