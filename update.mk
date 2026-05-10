ROOT_DIR := $(shell git rev-parse --show-toplevel)
HELM_DIR := $(ROOT_DIR)/.helm
HELM := helm --repository-config $(HELM_DIR)/repositories.yaml --repository-cache $(HELM_DIR)/repository

.PHONY: update
update: ## Update dependencies
update: \
	update-aqua \
	update-argocd \
	update-grafana-operator \
	update-kube-state-metrics

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

.PHONY: update-grafana-operator
update-grafana-operator:
	NEW_VERSION=$$(crane ls ghcr.io/grafana/helm-charts/grafana-operator | grep -e '^[0-9]' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/grafana-operator/kustomization.yaml

.PHONY: update-kube-state-metrics
update-kube-state-metrics:
	$(HELM) repo add prometheus-community https://prometheus-community.github.io/helm-charts
	$(HELM) repo update prometheus-community
	NEW_VERSION=$$($(HELM) search repo prometheus-community/kube-state-metrics --versions -ojson | jq -r '.[].version' | sort -V | tail -n1); \
	yq -iP ".helmCharts[0].version = \"$${NEW_VERSION}\"" $(ROOT_DIR)/apps/kube-state-metrics/kustomization.yaml
