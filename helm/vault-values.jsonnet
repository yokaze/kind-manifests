local images = import '../images.jsonnet';
local vault_version = std.split(images.vault, ':')[1];
{
  injector: {
    agentImage: {
      tag: vault_version,
    },
  },
  server: {
    ha: {
      enabled: true,
      raft: {
        enabled: true,
      },
    },
    image: {
      tag: vault_version,
    },
  },
}
