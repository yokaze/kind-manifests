#!/usr/bin/bash
curl -sk https://spire-spiffe-oidc-discovery-provider.spire-server/keys > /tmp/spire-keys
cat > /tmp/template.json <<'EOF'
{
  "allow_any_subject": true,
  "expires_at": "2030-01-01T00:00:00Z",
  "issuer": "https://oidc-discovery.yokaze.github.io",
  "scope": ["openid", "offline"]
}
EOF
jq -s '.[0] + { "jwk": .[1].keys[0] }' /tmp/template.json /tmp/spire-keys > /tmp/issuer
curl -s http://hydra-admin.hydra-system:4445/admin/trust/grants/jwt-bearer/issuers -X POST -d @/tmp/issuer
curl -s http://hydra-admin.hydra-system:4445/admin/trust/grants/jwt-bearer/issuers | jq .
curl -sL -o /tmp/hydra.tar.gz https://github.com/ory/hydra/releases/download/v2.2.0/hydra_2.2.0-linux_64bit.tar.gz
tar xzvf /tmp/hydra.tar.gz -O hydra > /tmp/hydra
chmod +x /tmp/hydra

for i in $(/tmp/hydra --endpoint http://hydra-admin.hydra-system:4445 list clients --format json | jq -r '.items[].client_id'); do
    /tmp/hydra --endpoint http://hydra-admin.hydra-system:4445 delete client $i
done
/tmp/hydra --endpoint http://hydra-admin.hydra-system:4445 list clients
/tmp/hydra --endpoint http://hydra-admin.hydra-system:4445 create client --name argocd-client --grant-type 'urn:ietf:params:oauth:grant-type:jwt-bearer' --format json | jq . > /tmp/client.json
/tmp/hydra --endpoint http://hydra-admin.hydra-system:4445 create client --name argocd-server --format json | jq . > /tmp/argocd.json
/tmp/hydra --endpoint http://hydra-admin.hydra-system:4445 list clients --format json | jq .

curl -sL -o /tmp/kubectl https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x /tmp/kubectl

if /tmp/kubectl get secret oauth2-client 2>/dev/null; then
    /tmp/kubectl delete secret oauth2-client
fi
/tmp/kubectl create secret generic oauth2-client \
    --from-literal=client_id=$(cat /tmp/client.json | jq -r '.client_id') \
    --from-literal=client_secret=$(cat /tmp/client.json | jq -r '.client_secret')
pause
