ROOT_DIR := $(shell git rev-parse --show-toplevel)
HELM_DIR := $(ROOT_DIR)/.helm
HELM := helm --repository-config $(HELM_DIR)/repositories.yaml --repository-cache $(HELM_DIR)/repository

.PHONY: setup
setup:
	mkdir -p $(HELM_DIR)

.PHONY: clean
clean:
	rm -rf $(HELM_DIR)

.PHONY: update-helm-jetstack
update-helm-jetstack:
	$(HELM) repo add jetstack https://charts.jetstack.io
	$(HELM) repo update jetstack

.PHONY: update-helm-prometheus-community
update-helm-prometheus-community:
	$(HELM) repo add prometheus-community https://prometheus-community.github.io/helm-charts
	$(HELM) repo update prometheus-community

.PHONY: update
update: ## Update dependencies
update: \
	update-accurate \
	update-aqua \
	update-argocd \
	update-cadvisor \
	update-cert-manager \
	update-crds-gateway \
	update-dependency-track \
	update-grafana-operator \
	update-headlamp \
	update-istio \
	update-kiali \
	update-kube-state-metrics \
	update-kubescape \
	update-loki \
	update-moco \
	update-node-exporter \
	update-traefik \
	update-trust-manager

.PHONY: update-accurate
update-accurate:
	$(HELM) repo add accurate https://cybozu-go.github.io/accurate
	$(HELM) repo update accurate
	NEW_VERSION=$$($(HELM) search repo accurate/accurate --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/accurate/kustomization.yaml

.PHONY: update-aqua
update-aqua:
	GH_TOKEN=$$(gh auth token); \
	aqua update; \
	aqua update-checksum -prune

.PHONY: update-argocd
update-argocd:
	$(HELM) repo add argo https://argoproj.github.io/argo-helm
	$(HELM) repo update argo
	NEW_VERSION=$$($(HELM) search repo argo/argo-cd --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/argocd/kustomization.yaml

.PHONY: update-cadvisor
update-cadvisor:
	NEW_VERSION=$$($(ROOT_DIR)/scripts/fetch-gh-releases google/cadvisor | tail -n1); \
	yq -iP ".resources[0] = \"https://github.com/google/cadvisor//deploy/kubernetes/base?ref=$${NEW_VERSION}\"" apps/cadvisor/kustomization.yaml

.PHONY: update-cert-manager
update-cert-manager: update-helm-jetstack
	NEW_VERSION=$$($(HELM) search repo jetstack/cert-manager --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/cert-manager/kustomization.yaml

.PHONY: update-crds-gateway
update-crds-gateway:
	NEW_VERSION=$$(gh release view -R kubernetes-sigs/gateway-api --json tagName --jq .tagName); \
	yq -iP "(.resources[] | select(contains(\"gateway-api\"))) = \"https://github.com/kubernetes-sigs/gateway-api/releases/download/$${NEW_VERSION}/standard-install.yaml\"" apps/crds/kustomization.yaml

.PHONY: update-dependency-track
update-dependency-track:
	$(HELM) repo add dependency-track https://dependencytrack.github.io/helm-charts
	$(HELM) repo update dependency-track
	NEW_VERSION=$$($(HELM) search repo dependency-track/dependency-track --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/dependency-track/kustomization.yaml

.PHONY: update-grafana-operator
update-grafana-operator:
	NEW_VERSION=$$(crane ls ghcr.io/grafana/helm-charts/grafana-operator | grep -e '^[0-9]' | sort -V | tail -n1); \
	yq -iP "(.resources[] | select(contains(\"grafana-operator\"))) = \"https://github.com/grafana/grafana-operator/releases/download/v$${NEW_VERSION}/crds.yaml\"" apps/crds/kustomization.yaml; \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/grafana-operator/kustomization.yaml

.PHONY: update-headlamp
update-headlamp:
	$(HELM) repo add headlamp https://kubernetes-sigs.github.io/headlamp
	$(HELM) repo update headlamp
	NEW_VERSION=$$($(HELM) search repo headlamp/headlamp --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/headlamp/kustomization.yaml

.PHONY: update-istio
update-istio:
	$(HELM) repo add istio https://istio-release.storage.googleapis.com/charts
	$(HELM) repo update istio
	NEW_VERSION=$$($(HELM) search repo istio/base --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/istio-base/kustomization.yaml; \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/istio/kustomization.yaml; \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/istio-cni/kustomization.yaml

.PHONY: update-kiali
update-kiali:
	$(HELM) repo add kiali https://kiali.org/helm-charts
	$(HELM) repo update kiali
	NEW_VERSION=$$($(HELM) search repo kiali/kiali-operator --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/kiali/kustomization.yaml

.PHONY: update-kube-state-metrics
update-kube-state-metrics: update-helm-prometheus-community
	NEW_VERSION=$$($(HELM) search repo prometheus-community/kube-state-metrics --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/kube-state-metrics/kustomization.yaml

.PHONY: update-kubescape
update-kubescape:
	$(HELM) repo add kubescape https://kubescape.github.io/helm-charts
	$(HELM) repo update kubescape
	NEW_VERSION=$$($(HELM) search repo kubescape/kubescape-operator --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/kubescape/kustomization.yaml

.PHONY: update-loki
update-loki:
	$(HELM) repo add grafana https://grafana.github.io/helm-charts
	$(HELM) repo update grafana
	NEW_VERSION=$$($(HELM) search repo grafana/loki --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/loki/kustomization.yaml

.PHONY: update-moco
update-moco:
	$(HELM) repo add moco https://cybozu-go.github.io/moco
	$(HELM) repo update moco
	NEW_VERSION=$$($(HELM) search repo moco/moco --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/moco/kustomization.yaml

.PHONY: update-node-exporter
update-node-exporter: update-helm-prometheus-community
	NEW_VERSION=$$($(HELM) search repo prometheus-community/prometheus-node-exporter --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/node-exporter/kustomization.yaml

.PHONY: update-traefik
update-traefik:
	$(HELM) repo add traefik https://traefik.github.io/charts
	$(HELM) repo update traefik
	NEW_VERSION=$$($(HELM) search repo traefik/traefik --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/traefik/kustomization.yaml

.PHONY: update-trust-manager
update-trust-manager: update-helm-jetstack
	NEW_VERSION=$$($(HELM) search repo jetstack/trust-manager --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/trust-manager/kustomization.yaml
