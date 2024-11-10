{
  hydra: {
    // https://github.com/ory/hydra/blob/master/driver/config/provider.go
    config: {
      dsn: 'memory',
      log: {
        level: 'debug',
      },
      oauth2: {
        grant: {
          jwt: {
            jti_optional: true,
          },
        },
      },
      urls: {
        'self': {
          issuer: 'https://hydra-public.hydra-system',
        },
      },
    },
  },
  maester: {
    enabled: false,
  },
}
