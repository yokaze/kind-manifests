{
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'grafana',
  },
  spec: {
    containers: [
      {
        name: 'grafana',
        image: 'grafana/grafana:7.4.3',
        env: [
          {
            name: 'GF_SECURITY_ADMIN_USER',
            valueFrom: {
              secretKeyRef: {
                name: 'grafana',
                key: 'username',
              },
            },
          },
          {
            name: 'GF_SECURITY_ADMIN_PASSWORD',
            valueFrom: {
              secretKeyRef: {
                name: 'grafana',
                key: 'password',
              },
            },
          },
          {
            name: 'GF_PATHS_PROVISIONING',
            value: '/usr/share/grafana/conf/provisioning',
          },
        ],
        volumeMounts: [
          {
            name: 'datasources',
            mountPath: '/usr/share/grafana/conf/provisioning/datasources',
            readOnly: true,
          },
        ],
      },
    ],
    volumes: [
      {
        name: 'datasources',
        configMap: {
          name: 'grafana-datasource',
        },
      },
    ],
  },
}
