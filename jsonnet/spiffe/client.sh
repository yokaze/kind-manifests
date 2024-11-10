#!/usr/bin/bash
curl -sL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/download/v2.13.0/argocd-linux-amd64
chmod +x /tmp/argocd
curl -sL -o /tmp/kubectl https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x /tmp/kubectl

curl -sL -o /tmp/hydra.tar.gz https://github.com/ory/hydra/releases/download/v2.2.0/hydra_2.2.0-linux_64bit.tar.gz
tar xzvf /tmp/hydra.tar.gz -O hydra > /tmp/hydra
chmod +x /tmp/hydra

ADMIN_PASSWORD=$(/tmp/kubectl get secret -n argocd argocd-initial-admin-secret -o json | jq -r .data.password | base64 -d)
/tmp/argocd login argocd-server.argocd --username admin --password ${ADMIN_PASSWORD} --plaintext
/tmp/argocd app list
/tmp/argocd logout argocd-server.argocd

CLIENT_ID=$(/tmp/kubectl get secret oauth2-client -ojson | jq -r .data.client_id | base64 -d)
CLIENT_SECRET=$(/tmp/kubectl get secret oauth2-client -ojson | jq -r .data.client_secret | base64 -d)
CLIENT_AUTH=$(echo -n "${CLIENT_ID}:${CLIENT_SECRET}" | base64 -w0)

JWT_SVID=$(cat /certs/jwt_svid.token)

curl -sk http://hydra-public.hydra-system:4444/oauth2/token \
--header 'Content-Type: application/x-www-form-urlencoded' \
--header "Authorization: Basic ${CLIENT_AUTH}" \
--data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer' \
--data-urlencode "assertion=${JWT_SVID}" | jq .
