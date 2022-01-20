export VAULT_ADDR="http://vault-0.vault-internal.vault:8200"
CLUSTER_KEYS=$(vault operator init -key-shares=1 -key-threshold=1)

UNSEAL_KEY=$(echo "${CLUSTER_KEYS}" | grep "Unseal Key" | sed -r 's/.*:\s(.*)/\1/')
vault operator unseal ${UNSEAL_KEY}
while ! echo "$(vault status)" | grep -E 'HA\sMode\s+active'; do sleep 1; done

export VAULT_ADDR="http://vault-1.vault-internal.vault:8200"
vault operator raft join http://vault-0.vault-internal.vault:8200
vault operator unseal ${UNSEAL_KEY}

export VAULT_ADDR="http://vault-2.vault-internal.vault:8200"
vault operator raft join http://vault-0.vault-internal.vault:8200
vault operator unseal ${UNSEAL_KEY}

echo
