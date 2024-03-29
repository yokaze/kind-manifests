local images = import '../images.jsonnet';
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
        image: images.grafana,
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
        ports: [{
          name: 'web',
          containerPort: 3000,
        }],
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
