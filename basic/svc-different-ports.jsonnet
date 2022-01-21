local images = import '../images.jsonnet';
local nginx = function(port) {
  apiVersion: 'v1',
  kind: 'Pod',
  metadata: {
    name: 'nginx-' + std.toString(port),
    labels: {
      app: 'nginx-mix',
    },
  },
  spec: {
    containers: [
      {
        name: 'nginx',
        image: images.nginx,
        command: ['bash', '-c', 'source /etc/nginx-port/nginx-port.sh', std.toString(port)],
        ports: [{
          name: 'web',
          containerPort: port,
        }],
        volumeMounts: [{
          name: 'nginx-port',
          mountPath: '/etc/nginx-port',
        }],
      },
    ],
    volumes: [{
      name: 'nginx-port',
      configMap: {
        name: 'nginx-port',
      },
    }],
  },
};
[
  {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      name: 'nginx-port',
    },
    data: {
      'nginx-port.sh': importstr 'resources/nginx-port.sh',
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: 'nginx-mix',
    },
    spec: {
      selector: {
        app: 'nginx-mix',
      },
      ports: [{
        port: 8080,
        targetPort: 'web',
      }],
    },
  },
] + [nginx(80), nginx(1080), nginx(2080)]
